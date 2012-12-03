

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

TYPES = [
  'int'
  'uint'
  'float'
  'ufloat'
  'long'
  'ulong'
  'double'
  '_const'
  'char'
  'uchar'
  'float16'
  'float32'
  'int16'
  'int32'
  'FILE'
  'typedef'
  'signed'
  'wchar_t'
  'wchar'
  'size_t'
  'struct'
  '__kernel'
  'void'
  'Void'
  'VOID'
  'bool'
  'boolean'
  'integer'
  'const'
]

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

  evaluate = []
  if options.evaluate?
    ev = toAST "var EVALUATED = #{options.evaluate.toString()};"
    console.log inspect ev, no, 20, yes
    ev = ev[1][0][1][0][1][3][0][1][1] # fuck this shit
    i = 0
    arr = options.evaluate()
    evaluate = {}
    for node in ev
      evaluate[resolve node] = arr[i++]
  debug "evaluated references: #{inspect evaluate, no, 20, yes}"

  ignore = []

  if options.ignore?
    ig = toAST "var IGNORED = #{options.ignore.toString()};"
    ig = ig[1][0][1][0][1][3][0][1][1]
    ignore = for node in ig
      resolve node
  debug "ignored references: #{inspect ignore, no, 20, yes}"

  # TEMPORARY OVERRIDE THIS SETTING
  ignore = ['mutable','mutateNow','_results'] 

  # Convert the function to AST. This is not the hard part for us.
  ast = toAST "var ROOT = #{func.toString()};"

  debug "AST: #{inspect ast, no, 20, yes}"
  
  includes = []

  scopes = [{}]
  scope = 0

  pretty = (n) -> "#{inspect n, no, 20, yes}"

  output = do parse = (nodes=ast, ind=0) ->
    return "" unless isArray nodes
    type = nodes[0]
    first = nodes[1]
    ind = 0 unless ind?
    #console.log "indentation: #{ind}"
    switch type

      when 'num'
        "#{first}"

      when 'dot'
        name = resolve nodes
        # try first to evaluate a complex.object.path
        if name of evaluate
          "#{eval name}"
        else if name in ignore
          ""
        else
          "#{if isArray(first) then parse(first) else first[1]}.#{nodes[2]}"
    
      when 'name'
        name = resolve nodes
        # try first to evaluate a simple name
        if name of evaluate
          "#{eval name}"
        else if name in ignore
          ""
        else
          if first in ['_void','VOID','Void'] then "void" else first.replace '$', '*'

      when 'string'
        debug "STRING"
        str = first
        str.replace "\n", "\\n"
        "\"#{str}\""

      when 'unary-postfix'
        debug "unary postfix"
        debug pretty nodes
        "#{parse nodes[2]}#{nodes[1]}"

      when 'unary-prefix'
        debug "unary prefix"
        debug pretty nodes
        "#{nodes[1]}#{parse nodes[2]}"

      when 'block'
        debug 'block'
        debug pretty nodes
        statements = for n in nodes[1]
          parse n, ind+1
        "{\n#{statements.join('')}#{indent ind}}\n"
      
      when 'break'
        debug 'break'
        debug pretty nodes
        "#{indent ind}break;\n"

      when 'continue'
        debug 'continue'
        debug pretty nodes
        "#{indent ind}continue;\n"

      when 'if'
        debug "if"
        debug pretty nodes
        "#{indent ind}if (#{parse nodes[1]}) #{parse nodes[2], ind}"

      when 'while'
        debug "WHILE LOOP"
        debug pretty nodes
        "#{indent ind}while (#{parse nodes[1]}) #{parse nodes[2], ind}"

      when 'binary'
        debug "BINARY OPERATION"
        replaceOperators =
          '===': '=='
          '!==': '!='

        first = if first of replaceOperators then replaceOperators[first] else first
        parse(nodes[2]) + " #{first} " + parse(nodes[3])

      when 'sub'
        debug "ARRAY INDEX"
        "#{parse first}[#{parse nodes[2]}]"

      when 'array'
        debug "ARRAY"
        debug pretty first
        elements = for n in first
          parse n
        "{#{elements.join(', ')}}"
      
      when 'return'
        debug "RETURN"
        # dot not wrap automatic return calls generated by coffee
        if first[0] is 'call' and first[1][1] in TYPES
          parse first
        else
          "#{indent ind}return #{parse first};\n"

      when 'assign'
        debug "ASSIGN"
        if nodes[3][0] is 'function'
          debug "FUNCTION ASSIGNEMENT"
          statements = for n in nodes[3][3]
            parse n, ind + 1
          debug "LOOKING FOR  DEFINITION: #{pretty nodes[3]}"
          nbArgs = nodes[3][2].length
          args = []
          if nbArgs > 0
            args = statements[1..nbArgs]
            args = for arg in args
              arg.trim().replace(';','').replace('\n','')
            statements = statements[nbArgs + 1..]

          #debug pretty args
          parse(nodes[2]) + "(#{args.join(',')}) {\n" + statements.join('') + "}\n"
        else
          debug "CLASSIC ASSIGN"
          parse(nodes[2]) + " = " + parse(nodes[3])

      when 'stat'
        debug "STATEMENT"
        debug pretty nodes

        if resolve(nodes[1][1]) is 'include'
          #debug "INCLUDE"
          #debug pretty nodes[1][2]
          "#{indent ind}#include <#{nodes[1][2][0][1]}>\n"
        else
          indent(ind) + parse(first, ind + 1) + ";\n"

      when 'call'
        debug "CALL"
        debug pretty nodes
        
        callee = resolve nodes[1]    
        params = nodes[2]    

        debug "CALLEE: #{callee}"
  
        if callee in ignore
          cut = params[0][3]
          buff = ""
          for node in cut
            buff += parse node, ind
          buff
        else if callee of evaluate
          debug "callee: #{callee} params: #{params}"
          debug "function: #{evaluate[callee]}"

          TMP = ->
          fakeAST = [ 
            'toplevel'
            [ 
              [ 
                'var'
                [ 
                  [ 
                    'TMP'
                     [ 
                       'function'
                        null
                        []
                        [ 
                          [ 
                            'return'
                            params[0]
                          ]
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]

          debug "fakeAST: #{pretty fakeAST}"
          code = pro.gen_code fakeAST, {}
          debug "code: #{code}"
          eval code
          debug "TMP: #{TMP}  res: #{TMP()}"
          result = evaluate[callee] TMP()
          if isString result
            "\"#{result}\""
          else # else number, probably.
            "#{result}"
        else
          param1 = params[0]
          debug "PARAM 1:"
          debug pretty param1
          if callee in TYPES
            debug "typed assignement"
            "#{callee} #{parse param1}"
          else
            if param1[0] is 'call' and param1[2][0][0] is 'assign'
              debug "two-level typing declaration"
            else
              
          
              params = for p in params
                parse p, ind
              "#{callee}(#{params.join ','})"
        ###
            buff = callee # type 1
            buff += resolve param1 # type 2
            if param1[2][0][3][0] is 'function'
              debug "of a function, great"
              buff += " #{resolve param1[2][0][2]}" # func name
              buff += " ()"
              buff += " {\n"
              body = ""
              statements = param1[2][0][3][3]
              #debug "body: #{inspect statements, no, 20, yes}"
              for statement in statements
                body += parse statement, ind + 1
              buff += body
              buff += "\n}\n"
            else
              debug "of a variable"
              buff += "#{nodeToString param1[2][0][4]}"
            res += buff
          else if param1[0] is 'assign'
            debug "simple level typing: #{inspect parameters, no, 20, yes}"
            buff = "#{resolve nodes[1]}" # type
            res += buff
            
          else # just a call
            debug "NOT a function"
            res += functionCall nodes[1], parameters, ind
        ###
      when 'assign' 
        
        debug "ASSIGNEMENT"
        debug pretty nodes
        ###
        if nodes[2][0] is 'sub'
          assigned = nodeToString nodes[2]
          value = parse nodes[3]
          "#{assigned} = #{value}"
        else if nodes[2][1] is 'main'
          args = nodes[3][2]
          statements = nodes[3][3]
          mainCall args, statements, ind
        else
          assigned = nodeToString nodes[2]
          value = parse nodes[3]
          "#{assigned} = #{value}"
        ###
      else
        buff = ""
        for node in nodes
          buff += parse node, ind
        buff

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

exports.run = (src, a, b) ->
  # TODO: add options
  onComplete = ->
  args = []
  if b?
    onComplete = b
    args = a
  else
    if a?
      if isFunction a
        onComplete = a
      else
        throw new Error "onComplete (second argument here) must be a function"
    else
      0#console.log "not args, no onComplete.."
  
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
      prog = spawn "./#{binFile}", args
      prog.stdin.end()
      _stdout = ""
      prog.stdout.on 'data', (data) ->
        _stdout += data.toString()

      _stderr = ""
      prog.stderr.on 'data', (data) ->
        _stderr += data.toString()

      prog.on 'exit', (code, signal) ->
        if code isnt 0
          #console.log "code is: #{code}"
          #  #throw new Error "process failed: #{_stderr}"
          onComplete _stderr, ""
        else
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

