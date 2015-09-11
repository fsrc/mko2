_     = require("lodash")
ensure = require("../util").ensure
constants = require("./mappings").constants

# ######################################################################
# Helper function to extract a variable or function argument
# so that it can be passed on to a function call or operator
buildLLVMArguments = (moduleState, expr) ->
  fnargs = _.pluck(moduleState.currentFunction.functionArgs.args, 'value')
  fnvars = moduleState.currentFunction.functionVars

  args = _.map(_.tail(expr.args), (arg) ->
    # if arg is an expression
    if arg.type == 'EXPR'
      throw "Can't handle this yet"

    # if arg isn't an expression but an variable
    else if arg.type == 'IDENT'
      # Look at arguments first
      if fnargindex = _.indexOf(fnargs, arg.value) > -1
        moduleState.currentFunction.llvmFunction.getParam(fnargindex)

      # Look if it's a defined variable
      else if fnvarindex = _.indexOf(fnvars, arg.value) > -1

      # If none of the above, then we raise an exception
      else
        ensure(expr, false, "Function does not contain variable")

    # arg must be an constant
    else
      constants[arg.type](arg.value))


# ######################################################################
# Built in operators such as ADD, SUB, MUL, DIV and so on
builtIn = {}
builtIn.add = (moduleState, expr) ->
  ensure(expr, moduleState.currentBuilder?, "Call not inside a block")

  args = buildLLVMArguments(moduleState, expr)

  moduleState.llvmVar = moduleState.currentBuilder.buildAdd(
    args[0], args[1], 'tmp')
  moduleState

builtIn.sub = (moduleState, expr) ->
  ensure(expr, moduleState.currentBuilder?, "Call not inside a block")

  args = buildLLVMArguments(moduleState, expr)

  moduleState.llvmVar = moduleState.currentBuilder.buildSub(
    args[0], args[1], 'tmp')
  moduleState

builtIn.call = (moduleState, expr) ->
  ensure(expr, moduleState.currentBuilder?, "Call not inside a block")

  args = buildLLVMArguments(moduleState, expr)

  callee = moduleState.functions[_.head(expr.args).value]

  moduleState.llvmVar = moduleState.currentBuilder.buildCall(
    callee.llvmFunction, args, 'tmp')
  moduleState

module.exports = builtIn
