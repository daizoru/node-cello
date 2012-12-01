{C, run} = require 'cello'
chai     = require 'chai'
expect = chai.expect

describe 'generating source code', ->

  generate = C
    indent: ""
    evaluate: -> [ Math.random, Math.round ]
    ignore: -> []
    debug: no

  it 'should support empty programs', (done) ->
    src = generate -> int main = -> return 0
    expect(src).to.equal """int main() {\nreturn 0;\n}\n\n"""
    done()

  it 'should support includes', (done) ->
    src = generate -> 
      include 'stdio.h'
      include 'string.h'
      int main = ->
    expect(src).to.equal """
#include <stdio.h>
#include <string.h>
int main() {\n}\n\n"""
    done()

  it 'should support simple programs', (done) ->
    src = generate -> 
      include 'stdio.h'
      include 'string.h'

      char buffer[1024]
      int main = ->
        FILE *inputFile = fopen "test.csv", 'r'
        fgets buffer, sizeof(buffer), inputFile
        char *line = strtok buffer, ','
        0
    expect(src).to.equal """#include <stdio.h>\n#include <string.h>
char buffer[1024];
int main() {
FILE * inputFile = fopen("test.csv","r");
fgets(buffer,sizeof(buffer),inputFile);
char * line = strtok(buffer,",");
return 0;
}\n\n"""
    done()

describe 'running programs', ->

  it 'should support output to stdout', (done) ->

    gen = C
      indent: "  "
      evaluate: -> [ Math.random, Math.round ]
      ignore: -> []
      debug: no

    src = gen ->
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


