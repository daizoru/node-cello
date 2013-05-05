{C, run, Program} = require 'cello'
chai              = require 'chai'
expect            = chai.expect

# default config
c = C
  indent: ""
  evaluate: -> [ Math.random, Math.round ]
  ignore: -> []
  debug: no

describe 'generating source code', ->

  it 'should support empty programs', (done) ->
    src = c -> int main = -> return 0
    expect(src).to.equal """int main() {\nreturn 0;\n}\n\n"""
    done()

  it 'should support includes', (done) ->
    src = c -> 
      include 'stdio.h'
      include 'string.h'
      int main = ->
    expect(src).to.equal """#include "stdio.h"\n#include "string.h"\nint main() {\n}\n\n"""
    done()

  it 'should support simple programs', (done) ->
    src = c -> 
      include 'stdio.h'
      include 'string.h'

      char buffer[1024]
      int main = ->
        FILE *inputFile = fopen "test.csv", 'r'
        fgets buffer, sizeof(buffer), inputFile
        char *line = strtok buffer, ','
        0
    expect(src).to.equal """#include "stdio.h"\n#include "string.h"\nchar buffer[1024];\nint main() {\nFILE * inputFile = fopen("test.csv","r");\nfgets(buffer,sizeof(buffer),inputFile);\nchar * line = strtok(buffer,",");\nreturn 0;\n}\n\n"""
    done()

describe 'running programs in simple mode', ->

  it 'should support output to stdout', (done) ->

    src = c ->
      include 'stdio.h'
      include 'stdlib.h'
      int x = 40
      int main = ->
        printf "hello, "
        int y = 43 + x / 10
        printf "result is %i", y
        0 

    run src, (err, output) ->
      expect(output).to.be.equal("hello, result is 47")
      done()

describe 'communicating with programs using pipes', ->

  it 'should output the input', (done) ->

    program = new Program c ->
      include 'stdio.h'
      int main = ->
        setbuf stdout, NULL
        char c = fgetc stdin
        while c isnt EOF
          printf "%c", c
          c = fgetc stdin
        0

    program.run [], ->
      program.write "hello"
      program.write " "
      program.write "world"
      program.close ({code, signal}) ->
        done()

    program.on 'stdout', (buff) -> expect("#{buff}").to.be.equal("hello world")
