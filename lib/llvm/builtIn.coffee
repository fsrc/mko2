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
operator = (moduleState, expr, fun) ->
  ensure(expr, moduleState.currentBuilder?, "Call not inside a block")

  args = buildLLVMArguments(moduleState, expr)

  moduleState.llvmVar =
    moduleState.currentBuilder[fun](args[0], args[1], 'tmp')
  moduleState

builtIn = {}
builtIn.add = (moduleState, expr) -> operator(moduleState, expr, "buildAdd")
builtIn.nswadd = (moduleState, expr) -> operator(moduleState, expr, "buildNSWAdd")
builtIn.nuwadd = (moduleState, expr) -> operator(moduleState, expr, "buildNUWAdd")
builtIn.fadd = (moduleState, expr) -> operator(moduleState, expr, "buildFAdd")
builtIn.sub = (moduleState, expr) -> operator(moduleState, expr, "buildSub")
builtIn.nswsub = (moduleState, expr) -> operator(moduleState, expr, "buildNSWSub")
builtIn.nuwsub = (moduleState, expr) -> operator(moduleState, expr, "buildNUWSub")
builtIn.fsub = (moduleState, expr) -> operator(moduleState, expr, "buildFSub")
builtIn.mul = (moduleState, expr) -> operator(moduleState, expr, "buildMul")
builtIn.nswmul = (moduleState, expr) -> operator(moduleState, expr, "buildNSWMul")
builtIn.nuwmul = (moduleState, expr) -> operator(moduleState, expr, "buildNUWMul")
builtIn.fmul = (moduleState, expr) -> operator(moduleState, expr, "buildFMul")
builtIn.udiv = (moduleState, expr) -> operator(moduleState, expr, "buildUDiv")
builtIn.sdiv = (moduleState, expr) -> operator(moduleState, expr, "buildSDiv")
builtIn.exactsdiv = (moduleState, expr) -> operator(moduleState, expr, "buildExactSDiv")
builtIn.fdiv = (moduleState, expr) -> operator(moduleState, expr, "buildFDiv")
builtIn.urem = (moduleState, expr) -> operator(moduleState, expr, "buildURem")
builtIn.srem = (moduleState, expr) -> operator(moduleState, expr, "buildSRem")
builtIn.frem = (moduleState, expr) -> operator(moduleState, expr, "buildFRem")
builtIn.shl = (moduleState, expr) -> operator(moduleState, expr, "buildShl")
builtIn.lshr = (moduleState, expr) -> operator(moduleState, expr, "buildLShr")
builtIn.ashr = (moduleState, expr) -> operator(moduleState, expr, "buildAShr")
builtIn.and = (moduleState, expr) -> operator(moduleState, expr, "buildAnd")
builtIn.or = (moduleState, expr) -> operator(moduleState, expr, "buildOr")
builtIn.xor = (moduleState, expr) -> operator(moduleState, expr, "buildXor")

builtIn.call = (moduleState, expr) ->
  ensure(expr, moduleState.currentBuilder?, "Call not inside a block")

  args = buildLLVMArguments(moduleState, expr)

  callee = moduleState.functions[_.head(expr.args).value]

  moduleState.llvmVar = moduleState.currentBuilder.buildCall(
    callee.llvmFunction, args, 'tmp')
  moduleState

module.exports = builtIn
