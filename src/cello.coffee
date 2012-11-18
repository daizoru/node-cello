
jsp = require "../node_modules/uglify-js/lib/parse-js"
pro = require "../node_modules/uglify-js/lib/process"
cs2js = require('../node_modules/coffee-script').compile
js2cs = require('../node_modules/js2coffee/lib/js2coffee').build

fs = require 'fs'
{inspect} = require 'util'

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


term = (n) ->
  
indent = (n=0,ch='\t') ->
  tmp = ""
  for [0...n]
    tmp += ch
  tmp

exports.C = C = (func) ->

 
  src = func.toString()
  # convert th
  src = "var ROOT = #{src};"

  console.log "src: #{src}"
  ast = toAST src


  console.log "AST: #{inspect ast, no, 20, yes}"
  
  includes = []

  scopes = [{}]
  scope = 0

  output = ""

  nodeToString = (n, ind = 0) ->
    console.log "VALUE #{inspect n, no, 20, yes}"
    if n[0] is 'binary'
      "(#{nodeToString n[2]} #{n[1]} #{nodeToString n[3]})"
    else if n[0] is 'string'
      str = n[1]
      str.replace("\n","\\n")
      "\"#{str}\""
    else
      "#{n[1]}"

  mainCall = (args, statements, ind = 0) ->
    console.log "MAIN #{args}  #{statements}"
    tmp = for arg in args
      nodeToString arg
    args = tmp.join ', '

    output += "#{indent ind}main(#{args}) {\n"
    tmp2 = for statement in statements
      parseStatement statement, ind + 1
    body = tmp2.join ';\n'
    #output += "void main(args) {\n#{body}\n}\n"
    output += "#{indent ind + 1}return 0;\n}\n"

  functionCall = (func, args, ind = 0) ->
    console.log "FUNCTION #{func} with args: #{args}"
    symbol = func[1]
    # special hack for typed vars
    if symbol in ['int','uint','float','ufloat','double','char']
      if args[0][0] is 'assign'
        console.log "ASSIGN: #{inspect args, no, 20, yes}"
        assignedVarName = args[0][2][1]
        assignedValue = nodeToString args[0][3]
        output += "#{indent ind}#{symbol} #{assignedVarName} = #{assignedValue};\n"
    else if symbol is 'include'
      output += "#{indent ind}#include <#{args[0][1]}>\n"
    else
      tmp = for arg in args
        nodeToString arg
      args = tmp.join(', ')
      output += "#{indent ind}#{func[1]}(#{args});\n"

  do parseStatement = (nodes=ast, ind = 0) ->
    n = "#{nodes}"
    if 'call,' is n[..4]
      functionCall nodes[1], nodes[2], ind
    else if 'assign,true,name,main,function,,' is n[..31]
      args = nodes[3][2]
      statements = nodes[3][3]
      mainCall args, statements, ind
    else if isArray nodes
      for node in nodes
        parseStatement node, ind


  # for custom headers
  headers = ""
  for include in includes
    headers += "#include <#{include}>\n"
  output = headers + output

exports.int   = int = ->
exports.float = float = ->
exports.include = include = (file) ->


src = C -> 
  include 'stdio.h'
  include 'stdlib.h'
  int x = 40
  main = ->
   int y = 43 + x
   printf "hello"

console.log "source:\n#{src}"
