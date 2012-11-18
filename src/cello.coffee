
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


varAssign = (n) ->
  console.log "varAssign #{inspect n, no, 20, yes}"
  type = n[1][1][1]
  symbol = n[1][2][0][2][1]
  value = n[1][2][0][3][1]
  "#{type} #{symbol} = #{value};\n"

term = (n) ->
  

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
  do parse = (nodes=ast) ->
    n = "#{nodes}"

    if 'stat,call,name,include,string,' is n[0..29]
      includes.push n[30..]
    else if "stat,call,name,int,assign,true,name," is n[0..35]
      output += varAssign nodes
    else if "stat,call,name,float,assign,true,name," is n[0..35]
      output += varAssign nodes
    else if "stat,call,name,ufloat,assign,true,name," is n[0..35]
      output += varAssign nodes
    else if "stat,call,name,uint,assign,true,name," is n[0..35]
      output += varAssign nodes
    else if "stat,call,name,double,assign,true,name," is n[0..35]
      output += varAssign nodes
    else if "stat,call,name,char,assign,true,name," is n[0..35]
      output += varAssign nodes


    if isArray nodes
      for node in nodes
        parse node



  headers = ""
  for include in includes
    headers += "#include <#{include}>\n"
  output = headers + output

[ 'stat', [ 'call', [ 'name', 'int' ], [ [ 'assign', true, [ 'name', 'x' ], [ 'num', 40 ] ] ] ] ]

[ 'stat', [ 'call', [ 'name', 'include' ], [ [ 'string', 'stdio.h' ] ] ] ]

exports.int   = int = ->
exports.float = float = ->
exports.include = include = (file) ->

src = C -> 
  include 'stdio.h'
  include 'stdlib.h'
  int x = 40
  main = ->
   int y = 43 + x
   console.log y

console.log "source:\n #{src}"
