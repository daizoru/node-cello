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

## Demo

```coffeescript
{ C } = require 'cello'

src = C ->
  include 'stdio.h'
  include 'stdlib.h'
  int x = 40
  main = ->
   int y = 43 + x
   printf "hello"

console.log src
```

Outputs: 

```C
#include <stdio.h>
#include <stdlib.h>
int x = 40;
void main() {
	int y = (43 + x);
	printf("hello");
}
```

Magic? yes. 

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

#### 0.0.2

 * added some options
 
#### 0.0.1

 * Removed debug console.logs
 * forgot to add uglify-js as dependency in the package.json!
 * removed useless dependencies in code

#### 0.0.0

 * Basic features are supported