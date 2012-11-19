{C, run} = require 'cello'
require 'colors'

options =
  indent: "  "
  evaluate: -> [ Math.random, Math.round ]
  ignore: -> []
  debug: yes

src = C(options) -> 

  __kernel VOID floatVectorSum = () ->
    int i = get_global_id 0
    #v1[i] = v1[i] + v2[i]

console.log "#{src}"

#run src, (err, output) ->
#  if err
#    throw new Error err.red
#  else
#    console.log "#{output}".green