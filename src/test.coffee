{C, compile, run} = require 'cello'

src = C(indent: "  ", debug: no) -> 
  include 'stdio.h'
  include 'stdlib.h'
  int x = 40
  main = ->
   int y = 43 + x
   printf "hello"

console.log "source:\n#{src}"

run src, (output) ->
  console.log "output: #{output}"