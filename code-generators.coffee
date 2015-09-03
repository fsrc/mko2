_     = require("lodash")
llvm  = require("llvm2")
log   = require("./util").logger(1, 'code-generators')

builder = new llvm.Builder()

generators = {}

generators.export = (context, head, tail, cb) ->


generators.call = (context, name, args, cb) ->
  log(10, "Call name: #{name.value}")
  log(20, args)

  builder = new llvm.Builder()
  builder.positionAtEnd(entry)


typeTranslation =
  int : llvm.Library.LLVMInt64Type

generators.fun = (context, head, tail, cb) ->
  rettype = _.head(tail)
  name    = _(tail).tail().head()
  arity   = _(tail).tail().tail().head()
  body    = _(tail).tail().tail().value()

  log(10, "Fun name", name.value)
  log(20, "Return", rettype.value)
  log(20, "Arity", arity.value.args)
  log(20, "Body", body)
  log(20, "Transformed", _(arity.value.args)
    .chunk(2)
    .map((arg) -> _.first(arg).value)
    .value())

  fn = context.module.addFunction(name.value, new llvm.FunctionType(
    typeTranslation[rettype.value]()
    _(arity.value.args)
      .chunk(2)
      .map((arg) -> typeTranslation[_.first(arg).value]())
      .value()
    false))

  entry = fn.appendBasicBlock("entry")



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
