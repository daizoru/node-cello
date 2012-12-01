{C, run} = require 'cello'
chai     = require 'chai'
expect = chai.expect

describe 'cello.C', ->
  generate = C
    indent: ""
    evaluate: -> [ Math.random, Math.round ]
    ignore: -> []
    debug: no

  it 'should support empty programs', (done) ->
    src = generate -> int main = -> 0
    console.log src
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

