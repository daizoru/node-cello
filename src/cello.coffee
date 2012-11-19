

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

resolve = (item) ->
  #console.log "RESOLVE/ #{inspect item, no, 20, yes}"
  name = ""
  if item[0] is 'dot'
    sub = ""
    if isArray item[1]
      sub = ""+resolve(item[1])
    else
      sub = item[1][1]
    name = "#{sub}.#{item[2]}"
  else if item[0] is 'name'
    name = item[1]
  #console.log "RESOLVED TO #{name}"
  name

CParser = (func,options={}) ->

  debug = options.debug ? no
  indentationStr = options.indent ? '\t'

  debug = if debug then console.log else ->

  
  indent = (n=0) ->
    tmp = ""
    if indentationStr
      for [0...n]
        tmp += indentationStr
    tmp

  evaluate = options.evaluate ? ->
  evaluate = toAST "var EVALUATED = #{evaluate.toString()};"
  evaluate = evaluate[1][0][1][0][1][3][0][1][1] # fuck this shit
  evaluate = for node in evaluate
    resolve node
  debug "evaluated references: #{inspect evaluate, no, 20, yes}"
  ignore = options.ignore ? ->
  ignore = toAST "var IGNORED = #{ignore.toString()};"
  ignore = ignore[1][0][1][0][1][3][0][1][1]
  ignore = for node in ignore
    resolve node
  
  debug "ignored references: #{inspect ignore, no, 20, yes}"
  ignore = ['mutable','mutateNow','_results'] # TEMPORARY HACK

  # Convert the function to AST. This is not the hard part for us.
  ast = toAST "var ROOT = #{func.toString()};"

  debug "AST: #{inspect ast, no, 20, yes}"
  
  includes = []

  scopes = [{}]
  scope = 0

  # used for values (not statements)
  # there is no ";" and no indentation
  nodeToString = (n, ind = 0) ->
    #
    debug "VALUE #{inspect n, no, 20, yes}"
    if n[0] is 'binary'
      "#{nodeToString n[2]} #{n[1]} #{nodeToString n[3]}"
    else if n[0] is 'sub'
      
      debug "SUB: #{n}"
      "#{n[1][1]}[#{n[2][1]}]"
    else if n[0] is 'array'
      elements = for element in n[1]
        nodeToString element
      "{#{elements.join(', ')}}"
    else if n[0] in ignore
      nodeToString n[1]
    else if resolve(n[1]) in evaluate
      code = pro.gen_code n, {}
      eval code
    else if n[0] is 'call'
      params = for p in n[2]
        nodeToString p
      "#{n[1][1]}(#{params.join(', ')})"
    else if n[0] is 'string'
      str = n[1]
      str.replace("\n","\\n")
      "\"#{str}\""
    else if isString n[1]
      "#{n[1].replace('$','*')}"
    else
      "#{n[1]}"

  functionDef = (args, statements, ind = 0) ->
    res = ""
    
    debug "FUNCTION #{args}  #{statements}"
    tmp = for arg in args
      nodeToString arg
    args = tmp

    #output += "#{indent ind}main(#{args}) {\n"
    body = ""
    tmp2 = for statement in statements
      body += parseStatement statement, ind + 1
    
    "int name(#{args}) {\n#{body}#{indent ind + 1}return 0;\n}\n"
    #output += "#{indent ind + 1}return 0;\n}\n"

  mainCall = (args, statements, ind = 0) ->
    res = ""
    
    debug "MAIN #{args}  #{statements}"
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
    
    debug "FUNCTION #{func[1]} with args: #{inspect args, no, 20, yes}"
    symbol = func[1]
    #if 'unary-postfix,' is n[..13]
    #  res += "nodes[2][1]#{nodes[1]}"
    if func[1][1] in ignore
      
      debug "bad function call, ignoring"
      res += parseStatement args
    # special hack for typed vars

    else if symbol in ['int','uint','float','ufloat','double','char','bool','boolean','_void']
      if args[0][0] is 'assign'
        debug "ASSIGN: #{inspect args, no, 20, yes}"
        assignedVarName = nodeToString args[0][2]
        assignedValue = nodeToString args[0][3]
        res += "#{indent ind}#{symbol} #{assignedVarName} = #{assignedValue};\n"
    else if symbol is 'include'
      res += "#{indent ind}#include <#{args[0][1]}>\n"
    else if symbol in ignore
      
      debug "function symbol #{symbol} is in ignore list #{ignore}"
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

    if isArray(nodes) and nodes[0] is 'unary-postfix'
      debug "unary postfix: #{inspect nodes, no, 20, yes}"
      res += "#{indent ind}#{nodes[2][1]}#{nodes[1]};"
    else if isArray(nodes) and nodes[0] is 'unary-prefix'
      debug "unary prefix: #{inspect nodes, no, 20, yes}"
      res += "#{indent ind}#{nodes[1]}#{nodes[2][1]};"
    else if isArray(nodes) and nodes[0] is 'while'
      
      debug "WHILE: #{inspect nodes[2], no, 20, yes}"
      cond = nodeToString nodes[1], ind
      body = ""
      for statement in nodes[2][1]
        body += parseStatement statement, ind + 1
      res += "#{indent ind}while (#{cond}) {\n#{body}\n#{indent ind}}\n"
    else if isArray(nodes) and nodes[0] is 'call'
      
      debug "checking if #{nodes[1][1]} is in #{ignore}"

      if nodes[1][1] in ignore
        
        debug "IGNORE func: #{nodes[1]}, args: #{inspect nodes[2], no, 20, yes}"
        for statement in nodes[2][0][3]
          res += parseStatement statement, ind
      else
        
        debug "NOT ignoring"
        res += functionCall nodes[1], nodes[2], ind

    else if isArray(nodes) and nodes[0] is 'assign' 
      
      debug "ASSIGNEMENT NOT USED????"
    
      if nodes[2][0] is 'sub'
        assigned = nodeToString nodes[2]
        value = parseStatement nodes[3]
        res += "#{assigned} = #{value}"
      else if nodes[2][1] is 'main'
        args = nodes[3][2]
        statements = nodes[3][3]
        res += mainCall args, statements, ind
      else
        assigned = nodeToString nodes[2]
        value = parseStatement nodes[3]
        res += "#{assigned} = #{value}"

    else if isArray(nodes)
      for node in nodes
        res += parseStatement node, ind
    res

  # for custom headers
  headers = ""
  for include in includes
    headers += "#include <#{include}>\n"
  output = headers + output + "\n" # 
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

    _gccstderr = ""
    gcc.stderr.on 'data', (data) ->
     _gccstderr += data.toString()

    gcc.on 'exit', (code, signal) ->
      if code isnt 0
        onComplete _gccstderr, ""
        return

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
        #debug "code is: #{code}"
        #  #throw new Error "process failed: #{_stderr}"
        fs.unlink binFile, ->
          fs.unlink srcFile, ->
        onComplete undefined, _stdout
    
    gcc.stdin.end()

###
TODO

we cannot use the coffee-script parse, because we need to parse at runtime,
when the code is already JS

so we need to strip out variables auto-generated by coffee, basically
_results


###

exports.C = C = (input) ->
  options = {}
  if isFunction input
    CParser input, options
  else
    options = input
    (input) -> CParser input, options

