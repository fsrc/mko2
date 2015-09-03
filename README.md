# mko2
The second generation of the mko language

# TODO
## compile time API
There should be a compile time API that macros and code generators can use.

## macro evaluator
Any macro should compile to IR on compile time and be executed by the jitter.

A tiny subset of features should be available to the macro environment.

Macros should be inter callable. In other words, you could build an library of helper macros that would never be used by other code than other macros.

## code generators
Any code generator should compile to IR on compile time and be executed by the jitter.

Mostly the same applies as with macros but there needs to be a API for LLVM in this context.
