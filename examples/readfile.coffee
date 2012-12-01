#!/usr/bin/coffee

# normally you should use the $ as a prefix for variables names
# that act as a pointer.
# that node-cello just translate the raw AST
{C} = require 'cello'

generate = C
  indent: "  "
  evaluate: -> [ Math.random, Math.round ]
  ignore: -> []
  debug: no

src = generate ->
  include 'stdio.h'
  include 'string.h'

  char buffer[1024]
  int main = ->
    FILE *inputFile = fopen "test.csv", 'r'
    fgets buffer, sizeof(buffer), inputFile
    char *line = strtok buffer, ','
    0

console.log src