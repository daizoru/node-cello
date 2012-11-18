
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

class Kernel
  constructor: (@symbol) ->

  setInterface: (vars={}) ->

  addStatement: ->

files = {}

exports.kernel = ->
  filePath = process.argv[1]
  filePath += ".js" unless filePath[-3..] is ".js"

  if filePath of files
    console.log "file #{filePath} already processed, skipping"
    return ->

  console.log "processing file #{filePath}"

  src = fs.readFileSync(filePath).toString()
  #console.log "src: #{}"
  #src = func.toString()
  # convert th
  console.log "src: #{src}"
  ast = toAST src

  console.log "AST: #{inspect ast, no, 20, yes}"

  kernels = {}
  do getKernels = (node=ast) ->

    if isArray node
      if node[0..22] is "call,name,kernel,assign,true,"
        name = node[2][0][3][1]
        console.log "found an OpenCL kernel called #{name}"
        kernels[name] = new Kernel name



exports.Kernel  = Kernel
exports.integer = ->
exports.float   = ->



