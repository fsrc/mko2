# mko2
The second generation of the mko language

First generation of the compiler should be written in Coffee-Script on node with LLVM bindings.

The Coffee-Script code should be written in such a way that it is easy to translate to mko. The goal is that the second generation of the compiler should first be compiled with the first generation of the compiler. Finaly the compiler should be compiled with it self.

The language is inspired by lisp and node.js, obviously with touches of JavaScript. What sets it apart is no state manipulation allowed, static typing and macro support.

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

