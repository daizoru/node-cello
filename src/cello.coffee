

fs = require 'fs'
{inspect} = require 'util'
spawn = require('child_process').spawn

tmp = require 'tmp'

jsp = require "../node_modules/uglify-js/lib/parse-js"
pro = require "../node_modules/uglify-js/lib/process"

copy = (a) -> JSON.parse(JSON.stringify(a))

P           = (p=0.5) -> + (Math.random() < p)
isFunction  = (obj) -> !!(obj and obj.constructor and obj.call and obj.apply)
isUndefined = (obj) -> typeof obj is 'undefined'
isArray     = (obj) -> Array.isArray obj
isString    = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))
isNumber    = (obj) -> (obj is +obj) or toString.call(obj) is '[object Number]'
isBoolean   = (obj) -> obj is true or obj is false
isString    = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))

exports.toAST = toAST = (f) -> jsp.parse f.toString()


CParser = (func,options={}) ->

  debug = options.debug ? no
  indentationStr = options.indent ? '\t'
  
  indent = (n=0) ->
    tmp = ""
    if indentationStr
      for [0...n]
        tmp += indentationStr
    tmp

  ignore = options.ignore ? ->
  ignore = "var IGNORED = #{ignore.toString()};"
  if debug
    console.log "ignore: #{ignore}"
  ignore = ['mutable','mutateNow'] # TEMPORARY HACK


  src = func.toString()
  # convert th
  src = "var ROOT = #{src};"

  if debug
    console.log "src: #{src}"
  ast = toAST src


  if debug
    console.log "AST: #{inspect ast, no, 20, yes}"
  
  includes = []

  scopes = [{}]
  scope = 0

  nodeToString = (n, ind = 0) ->
    #if debug
    #  console.log "VALUE #{inspect n, no, 20, yes}"
    if n[0] is 'binary'
      "(#{nodeToString n[2]} #{n[1]} #{nodeToString n[3]})"
    else if n[0] is 'string'
      str = n[1]
      str.replace("\n","\\n")
      "\"#{str}\""
    else if n[0] in ignore
      nodeToString n[1]
    else
      "#{n[1]}"

  mainCall = (args, statements, ind = 0) ->
    res = ""
    if debug
      console.log "MAIN #{args}  #{statements}"
    tmp = for arg in args
      nodeToString arg
    args = tmp

    #output += "#{indent ind}main(#{args}) {\n"
    body = ""
    tmp2 = for statement in statements
      body += parseStatement statement, ind + 1
    
    "int main(#{args}) {\n#{body}#{indent ind + 1}return 0;\n}\n"
    #output += "#{indent ind + 1}return 0;\n}\n"

  functionCall = (func, args, ind = 0) ->
    res = ""
    if debug
      console.log "FUNCTION #{func[1]} with args: #{inspect args, no, 20, yes}"
    symbol = func[1]
    # special hack for typed vars
    if symbol in ['int','uint','float','ufloat','double','char']
      if args[0][0] is 'assign'
        if debug
          console.log "ASSIGN: #{inspect args, no, 20, yes}"
        assignedVarName = args[0][2][1]
        assignedValue = 0

        if args[0][3][0] is 'call'
          assignedValue = functionCall args[0][3][1], args[0][3][2]
        else
          assignedValue = nodeToString args[0][3]

        res += "#{indent ind}#{symbol} #{assignedVarName} = #{assignedValue};\n"
    else if symbol is 'include'
      res += "#{indent ind}#include <#{args[0][1]}>\n"
    else if symbol in ignore
      if debug
        console.log "function symbol #{symbol} is in ignore list #{ignore}"
      res += nodeToString args[0], ind
    else
      tmp = for arg in args
        nodeToString arg
      args = tmp
      res += "#{indent ind}#{func[1]}(#{args});\n"
    res

  output = do parseStatement = (nodes=ast, ind = 0) ->
    res = ""
    n = "#{nodes}"
    if 'call,' is n[..4]
      if debug
        console.log "checking if #{nodes[1][1]} is in #{ignore}"
      if nodes[1][1] in ignore
        if debug
          console.log "IGNORE func: #{nodes[1]}, args: #{inspect nodes[2], no, 20, yes}"
        for statement in nodes[2][0][3]
          res += parseStatement statement, ind
      else
        if debug
          console.log "NOT ignoring"
        res += functionCall nodes[1], nodes[2], ind
    else if 'assign,true,name,main,function,,' is n[..31]
      args = nodes[3][2]
      statements = nodes[3][3]
      res += mainCall args, statements, ind
    else if isArray nodes
      for node in nodes
        res += parseStatement node, ind
    res

  # for custom headers
  headers = ""
  for include in includes
    headers += "#include <#{include}>\n"
  output = headers + output
  output

exports.compile = (src, onComplete=->) ->
  fs.writeFile 'output.c', src, (err) ->
    throw err if err
    gcc = spawn 'gcc', ['output.c', '-o-']
    gcc.on 'exit', (code, signal) ->
      onComplete gcc.stdout
    gcc.stdin.end()

exports.run = (src, onComplete=->) ->
  # TODO: add options
  srcFile = 'output.c'
  binFile = 'output'
  fs.writeFile srcFile, src, (err) ->
    throw err if err
    gcc = spawn 'gcc', [srcFile, '-o', binFile]
    gcc.on 'exit', (code, signal) ->
 
      #console.log "gcc exit code is: #{code}"
      #console.log 'gcc terminated due to receipt of signal '+signal
      prog = spawn "./#{binFile}", []
      prog.stdin.end()
      _stdout = ""
      prog.stdout.on 'data', (data) ->
        _stdout += data.toString()

      _stderr = ""
      prog.stderr.on 'data', (data) ->
        _stderr += data.toString()

      prog.on 'exit', (code, signal) ->
        #if code isnt 0
        #  console.log "code is: #{code}"
        #  #throw new Error "process failed: #{_stderr}"
        fs.unlink binFile, ->
          fs.unlink srcFile, ->
        onComplete _stdout
    
    gcc.stdin.end()



exports.C = C = (input) ->
  options = {}
  if isFunction input
    CParser input, options
  else
    options = input
    (input) -> CParser input, options

