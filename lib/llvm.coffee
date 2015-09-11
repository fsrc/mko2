_     = require("lodash")
llvm  = require("llvm2")

log   = require("./util").logger(20, 'llvm')
pp    = require("./util").pp
strip = require("./util").strip

typeMap =
  "int-type" : llvm.Library.LLVMInt64Type

constants =
  INT : (value) ->
    llvm.Library.LLVMConstInt(
      typeMap["int-type"](),
      parseInt(value),
      false)

ensureExpr = (expr, truthy, msg) ->
  if not truthy
    console.log expr
    throw msg

builtIn = {}
builtIn.add = (moduleState, expr) ->
  ensureExpr(expr, moduleState.currentBuilder?, "Call not inside a block")

  fnargs = _.pluck(moduleState.currentFunction.functionArgs.args, 'value')
  fnvars = moduleState.currentFunction.functionVars

  args = _.map(_.tail(expr.args), (arg) ->
    # if arg is an expression
    if arg.type == 'EXPR'
      throw "Can't handle this yet"

    # if arg isn't an expression but an variable
    else if arg.type == 'IDENT'
      fnargindex = _.indexOf(fnargs, arg.value)
      ensureExpr(expr, fnargindex > -1, "Function does not contain variable")
      moduleState.currentFunction.llvmFunction.getParam(fnargindex)

    # arg must be an constant
    else
      constants[arg.type](arg.value)
  )
  moduleState.llvmVar = moduleState.currentBuilder.buildAdd(
    args[0], args[1], 'tmp')
  moduleState

convert = {}
convert.function = (moduleState, expr) ->
  lastExpr = _.last(expr.args)
  ensureExpr(expr,
    expr.args.length > 2 and
    expr.args.length < 5,
    "Function type declaration must contain name and list of types")
  ensureExpr(expr,
    lastExpr.type == "EXPR" and
    lastExpr.args.length > 0,
    "Function type must define at least a return type")

  types = _.last(expr.args).args

  retType = typeMap[_.head(types).value]()
  argTypes = _.map(_.tail(types), (type) -> typeMap[type.value]())

  moduleState.types[expr.args[1].value] =
    typeName : "function-type"
    llvmType : new llvm.FunctionType(retType, argTypes, false)
  moduleState

convert.define = (moduleState, expr) ->
  ensureExpr(expr,
    expr.args.length > 3 and
    expr.args.length < 5,
    "Function definition must contain function-type, function-name arity and list of blocks")
  type    = moduleState.types[expr.args[1].value]
  varName = expr.args[2].value

  if type.typeName == "function-type"
    args   = _.head(expr.args[3].args)
    blocks = _.tail(expr.args[3].args)

    moduleState.currentFunction = moduleState.functions[varName] =
      llvmFunction : moduleState.llvmModule.addFunction(varName, type.llvmType)
      functionArgs : args
      functionVars : []

    moduleState = _.reduce(blocks, (moduleState, block) ->
      convert.block(moduleState, block)
    , moduleState)

    moduleState.currentFunction = null
    moduleState

  moduleState

convert.block = (moduleState, expr) ->
  moduleState.currentFunction.blocks ?= {}

  blockName = expr.args[1].value
  block = moduleState.currentFunction.llvmFunction.appendBasicBlock(blockName)

  moduleState.currentFunction.blocks[blockName] = block

  builder = new llvm.Builder()
  builder.positionAtEnd(block)
  moduleState.currentBuilder = builder

  expressions = _.tail(_.tail(expr.args))

  moduleState = _.reduce(expressions, (moduleState, expr) ->
    convert.exprToAst(moduleState, expr)
  , moduleState)

  builder.buildRet(moduleState.llvmVar)

  moduleState.llvmVar = null

  moduleState.currentBuilder = null

  moduleState

convert.call = (moduleState, expr) ->
  ensureExpr(expr, moduleState.currentBuilder?, "Call not inside a block")

  fnargs = _.pluck(moduleState.currentFunction.functionArgs.args, 'value')
  fnvars = moduleState.currentFunction.functionVars

  args = _.map(_.tail(expr.args), (arg) ->
    # if arg is an expression
    if arg.type == 'EXPR'
      throw "Can't handle this yet"

    # if arg isn't an expression but an variable
    else if arg.type == 'IDENT'
      fnargindex = _.indexOf(fnargs, arg.value)
      ensureExpr(expr, fnargindex > -1, "Function does not contain variable")
      moduleState.currentFunction.llvmFunction.getParam(fnargindex)

    # arg must be an constant
    else
      constants[arg.type](arg.value)
  )
  callee = moduleState.functions[_.head(expr.args).value]

  moduleState.llvmVar = moduleState.currentBuilder.buildCall(
    callee.llvmFunction, args, 'tmp')
  moduleState

convert.exprToAst = (moduleState, expr) ->
  ensureExpr(expr, expr.type == "EXPR", "Not an expression")
  headArg = _.head(expr.args)
  ensureExpr(expr,
    (headArg.type != "EXPR") or
    (headArg.type == "EXPR" and headArg.args?[0] == "meta"),
    "Can't use expression as an identifier")

  if headArg.args?[0] == "meta"
    # Handle meta tag
    moduleState
  else
    ident = headArg.value
    log(20, "Expression with ident #{ident}")
    ensureExpr(headArg,
      _.has(convert, ident) or
      _.has(builtIn, ident) or
      _.has(moduleState.functions, ident),
      "Identifier does not exist")

    if _.has(convert, ident)
      convert[ident](moduleState, expr)

    else if _.has(builtIn, ident)
      builtIn[ident](moduleState, expr)

    else
      convert.call(moduleState, expr)

convert.module = (name) ->
  llvmModule : new llvm.Module(name)
  types : {}
  functions : {}

module.exports = convert

