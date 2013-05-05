node-cello
==========

*a simple DSL to generate simple C programs*

Alternative title:
 
*A magical DSL to generate C code from CoffeeScript*

## Introduction

node-cello is a work-in-progress DSL and template engine for generating C programs.

## Warning

This is an experimental project, and should be used with care.

For the moment only basic C code can be generated using this library.

The code is a bit messy, and architecture/syntax is not fixed yet.

However it is already on NPM repository because:

1. it basically works
2. it's a dependency of another project

Thank you for your understanding!

## Documentation

### Options

You can pass parameters to cello.
For the moment only a few are supported:

* indent: the indentation string to use (eg. "   " or "\t")
* debug: some debug messages - for development only
* evaluate: a func which return a list of JS references to interpret BEFORE code generation
* ignore: a func which return a list of JS references to ignore (won't be translated to C)

Example:

```CoffeeScript
src = C(indent: "  ", debug: yes) -> 
  main = ->
```

### Compiling

Experimental support of gcc is implemented:

```CoffeeScript
{C, run} = require 'cello'
src = C -> main = -> printf "hello world"
run src, (output) -> console.log "output: #{output}"
```


### Communicating

You can execute a program, and read/write from it, as it were a bi-directional stream:

```CoffeeScript
{C, run} = require 'cello'
src = C -> main = -> printf "hello world"
run src, (output) -> console.log "output: #{output}"
```

## Demos

### Demo 1

```coffeescript
{ C, run } = require 'cello'

src = C ->
  include 'stdio.h'
  int x = 40
  main = ->
   int y = 43 + x
   printf "hello"

# compile & run
run src, console.log
```

Will generate this code: 

```C
#include <stdio.h>
int x = 40;
int main() {
	int y = (43 + x);
	printf("hello");
	return 0;
}
```

Then it will run and print 'hello'. Magic? yes. 

### Demo 2

```CoffeeScript
{C, run} = require 'cello'

options =
  indent: "  "
  evaluate: -> [ Math.random, Math.round ]
  ignore: -> []
  debug: no

src = C(options) -> 
  include 'stdio.h'
  include 'stdlib.h'

  int x = 40

  main = ->

    printf "hello, "
    int y = 43 + x / 10
    printf "result is %i", y

    int a = [ 0, 0, 0, 1, 0 ]
    int b[5] = [ 0 ]

    float seed = Math.round Math.random() * 1000
 
    #int compute = (a=int, b=int) -> a + b

    char p1 = 127
    char $p2 = malloc sizeof char

    int i = 0
    while i < 10000
      ++i
    while i > 10000
      i--   

    0 

    

console.log "#{src}"

run src, (err, output) ->
  if err
    throw new Error err
  else
    console.log "#{output}"
```

will generate:

```C
#include <stdio.h>
#include <stdlib.h>
int x = 40;
int main() {
  printf("hello, ");
  int y = 43 + x / 10;
  printf("result is %i",y);
  int a = {0, 0, 0, 1, 0};
  int b[5] = {0};
  float seed = 926;
  char p1 = 127;
  char *p2 = malloc(sizeof(char));
  int i = 0;
  while (i < 10000) {
    ++i;
  }
  while (i > 10000) {
    i--;
  }
  return 0;
}

```

with output:

```
hello
```

### Demo 3

This demo shows how to communicate with the sub C program:

```CoffeeScript
{C, Program} = require 'cello'

program = new Program C() ->
  include 'stdio.h'
  int main = ->
    setbuf stdout, NULL
    char c = fgetc stdin
    while c isnt EOF
      printf "%c", c
      c = fgetc stdin
    0

# call the program, here with an empty argument list
program.run [], ->
  console.log "demo.program started"
  program.write "hello"
  program.write "world"
  program.close ({code, signal}) -> console.log "closed: #{code}"

program.on 'stdout',  (buff) ->  console.log "output: " + buff.toString()
program.on 'stderr',  (buff) ->  console.log "demo.stderr: " + buff.toString()
```


## WISHLIST FOR SANTA

 * support for inline C statements, as lone strings (eg. """(void *) i;""")
 * support for Class: http://stackoverflow.com/a/840703
 * support for new (either malloc, or just ignore it?, but at least it will feel a bit more natural)
 * support for function pointers allocation
 * support for &? (altough it's mostly used for func pointers, and it is implicit)
 * find a more elegant solution than using 'Void' as alias of 'void'?
 * find an elegant solution to support const (which is forbidden in Coffee/JavaScript)
 * support typedef
 * support struct
 * add more doc (eg. the if / while example)
 * support for loops (by not translating directly but generating boilerplate)
 * support pointer casting
 * Type inference (eg. that "i = 0" will convert to "int i = 0")
 * Implement ALL C language features
 * more unit tests
 * more CoffeeScript magic (eg. doing more implicit stuff such as: x = y for x in [0...2])

## Changelog

#### 0.1.0

 * added a new Program class
 * support for bi-directional communication using unix pipes


#### 0.0.9 - unreleased
#### 0.0.8 - unreleased

 * Support for include 'test.h' and include '<stdlib.h>'
 
#### 0.0.7

 * Added support for break and continue
 * added support for functions (eg. main) args
 * added support for command line args (when calling run())

#### 0.0.6

 * fixed a bug with missing parameters in the options
 * Added support for "if" expressiion
 * Simplified "while" expression
 * Support for blocks "{}"
 * Added basic unit tests

#### 0.0.5

 * Rewrote nearly everything from scratch
 * should be f***ing more robust now
 * moved debug scripts to /examples
 * experimenting with OpenCL kernel generation (yeah for node-evolve!)

#### 0.0.4

 Added basic support for:

 * array declaration and initialization
 * pointers (using $ instead of *)
 * while loops

 Also fixed a few bugs around

#### 0.0.3

 * basic support for gcc compilation and execution

#### 0.0.2

 * added some options

#### 0.0.1

 * Removed debug console.logs
 * forgot to add uglify-js as dependency in the package.json!
 * removed useless dependencies in code

#### 0.0.0

 * Basic features are supported