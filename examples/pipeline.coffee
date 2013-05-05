#!/usr/bin/coffee

{C, Program} = require 'cello'

config = C
  indent: "  "
  evaluate: -> [ Math.random, Math.round ]
  ignore: -> []
  debug: yes

program = new Program config ->
  include 'stdio.h'
  int main = ->
    setbuf stdout, NULL
    char c = fgetc stdin
    while c isnt EOF
      printf "%c", c
      c = fgetc stdin
    0

program.run [], ->
  console.log "demo.program started"
  program.write "hello"
  program.write "world"
  program.close ({code, signal}) ->
    console.log "closed: #{code}"

program.on 'stdout', (buff) ->
  console.log "output: " + buff.toString()

program.on 'stderr',  (buff) -> 
  console.log "demo.stderr: " + buff.toString()
