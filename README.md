node-cello
==========

WORK IN PROGRESS

for now it is pretty useless, but once a bit more advanced,
it will be a magical DSL to generate C code from CoffeeScript:

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

