_     = require("lodash")
llvm  = require("llvm2")

log   = require("../util").logger(0, 'llvm')
pp    = require("../util").pp
strip = require("../util").strip
ensure = require("../util").ensure

builtIn = require("./builtIn")
typeMap = require("./mappings").typeMap



########################################################################
# Conversion of high level constructs such as
# declarations, defines, expressions and blocks
convert = {}
convert.function = (moduleState, expr) ->
  lastExpr = _.last(expr.args)
  ensure(expr,
    expr.args.length > 2 and
    expr.args.length < 5,
    "Function type declaration must contain name and list of types")
  ensure(expr,
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
  ensure(expr,
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

  else if type.typeName == "int-type"

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


convert.exprToAst = (moduleState, expr) ->
  ensure(expr, expr.type == "EXPR", "Not an expression")
  headArg = _.head(expr.args)
  ensure(expr,
    (headArg.type != "EXPR") or
    (headArg.type == "EXPR" and headArg.args?[0] == "meta"),
    "Can't use expression as an identifier")

  if headArg.args?[0] == "meta"
    # Handle meta tag
    moduleState
  else
    ident = headArg.value
    log(20, "Expression with ident #{ident}")
    ensure(headArg,
      _.has(convert, ident) or
      _.has(builtIn, ident) or
      _.has(moduleState.functions, ident),
      "Identifier does not exist")

    if _.has(convert, ident)
      convert[ident](moduleState, expr)

    else if _.has(builtIn, ident)
      builtIn[ident](moduleState, expr)

    else
      builtIn.call(moduleState, expr)

convert.module = (name) ->
  llvmModule : new llvm.Module(name)
  types : {}
  functions : {}

module.exports = convert

