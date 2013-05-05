{inspect} = require 'util'
{C, run} = require 'cello'
cl = require "node-opencl"
require 'colors'
log = console.log
pretty = (n) -> JSON.stringify n, null, 2 # "#{inspect n, no, 20, yes}"


options =
  indent: "  "
  evaluate: -> [ Math.random, Math.round ]
  ignore: -> []
  debug: no

src = C(options) -> 

  #__kernel VOID floatVectorSum = () ->
  #  int i = get_global_id 0
  #  #v1[i] = v1[i] + v2[i]

  
  __kernel VOID f = () ->
    #(char add, __global const char *input, __global char *output) 
    int i = 0
    while i++ < size
      output[i] = 2 * input[i] + add

    0
 
console.log "#{src}"

#run src, (err, output) ->
#  if err
#    throw new Error err.red
#  else
#    console.log "#{output}".green

platforms = cl.getPlatforms()
for platform in platforms
  log "Platform: " + pretty platform
  log "name = " + platform.getInfo cl.PLATFORM_NAME
  devices = platform.getDevices cl.DEVICE_TYPE_ALL
  log "Devices: " + pretty devices
  for device in devices
    context = platform.createContext [device]
    queue = context.createCommandQueue device
    log "Context " + pretty context
    log "Queue: " + pretty queue
    size = 32
    
    #"output[get_global_id(0)] = 2 * input[get_global_id(0)];" +
    source = """__kernel void f(char add, __global const char *input, __global char *output) {
      for (int i = 0; i < #{size}; i++) {
        output[i] = 2 * input[i] + add;
      }
    }"""
    program = context.createProgramWithSource source
    program.build()
    log "Program: " + pretty program
    input  = context.createBuffer cl.MEM_READ_WRITE, size
    output = context.createBuffer cl.MEM_READ_WRITE, size
    log "output: " + pretty output
    kernel = program.createKernel "f"
    kernel.setArg 0, 3, cl.types.BYTE
    kernel.setArg 1, input
    kernel.setArg 2, output
    log "kernel: " + pretty kernel
    e = queue.enqueueTask kernel
    log "task event: " + pretty e
    outputBuffer = new Buffer size
    queue.enqueueReadBuffer output, true, 0, size, outputBuffer
    inputBuffer = new Buffer size
    queue.enqueueReadBuffer input, true, 0, size, inputBuffer
    log inputBuffer
    log outputBuffer
    log "enqueued task"
    queue.finish()
    log "finished"

#var b = context.