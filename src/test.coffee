{C} = require 'cello'

src = C(indent: "  ", debug: yes) -> 
  include 'stdio.h'
  include 'stdlib.h'
  int x = 40
  main = ->
   int y = 43 + x
   printf "hello"

console.log "source:\n#{src}"