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

## Demo 1

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

## Demo 2

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

## Documentation

### Options

You can pass parameters to cello.
For the moment only two are supported:

* indent: the indentation string to use (eg. "   " or "\n")
* debug: some debug messages - for development only

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

## TODO

* Find a way to support typed parameters (eg. type inference?)
* Implement more C language features
* Implement MUCH MORE C language features
* Implement ALL C language features (well, ideally)
* unit tests

### More TODO: built-in compiler support? 

* add support for an 'inline' mode like in Perl
* autoconfing
* on-the-fly compilation
* execute the binary
* handle the STDIN / STDOUT wrapping

## Changelog

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