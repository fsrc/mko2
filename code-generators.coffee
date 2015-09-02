_     = require("lodash")
llvm  = require("llvm2")
log   = require("./util").logger(20, 'code-generators')

builder = new llvm.Builder()

generators = {}

generators.export = (context, head, tail, cb) ->

generators.call = (context, name, args, cb) ->
  log(10, "Call name: #{name.value}")
  log(20, args)


generators.fun = (context, head, tail, cb) ->
  name = _.head(tail)
  arity = _(tail).tail().head()
  body = _(tail).tail().tail().value()

  log(10, "Fun name: #{name.value}")
  log(20, "Arity", arity)
  log(20, "Body", body)

generate = (context, expr, cb) ->
  do (context, expr, cb) ->
    head = _.head(expr.args)
    tail = _.tail(expr.args)

    # Is it a built in macro?
    if _.has(generators, head.value)
      generators[head.value](context, head, tail, cb)
    # Or generate a function call
    else
      generators.call(context, head, tail, cb)

context = (name) ->
  module: new llvm.Module(name)
  bitcode: []

module.exports =
  generate : generate
  context : context
