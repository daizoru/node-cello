{C, compile, run} = require 'cello'
require 'colors'

options =
  indent: "  "
  evaluate: -> [ Math.random, Math.round ]
  ignore: -> []
  debug: yes

src = C(options) -> 
  include 'stdio.h'
  include 'stdlib.h'

  int x = 40

  int main = ->

    printf "hello, "
    int y = 43 + x / 10
    printf "result is %i", y

    int a = [ 0, 0, 0, 1, 0 ]
    int b[5] = [ 0 ]

    float seed = Math.round Math.random() * 1000
 
    #int compute = (a=int, b=int) -> x + y

    char p1 = 127
    char $p2 = malloc sizeof char

    int i = 0
    while i < 10000
      ++i
    while i > 10000
      i--   

    0 

console.log "#{src}"
console.log "running program"
run src, (err, output) ->
  console.log "program ran"
  if err
    throw new Error err.red
  else
    console.log "program terminated"
    console.log "#{output}".green