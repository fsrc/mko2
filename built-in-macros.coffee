_     = require("lodash")
fop = require("./file-operations")
log   = require("./util").logger(1, 'built-in-macros')

TOK = require("./tokens")
createTokenizer = require("./tokenizer")
createParser = require("./parser")
codeGenerators = require("./code-generators")
astTemplates = require("./ast-manipulators")

macros = {}
user = {}

isMacro = (head) ->
  if _.has(macros, head.value) or _.has(user, head.value)
    true
  else
    false


doEvalMacro = (head, tail, cb) ->
  do (head, tail, cb) ->
    # Is it a built in macro?
    if _.has(macros, head.value)
      macros[head.value](head, tail, cb)

    # Is it a user defined macro?
    else if _.has(user, head.value)
      user[head.value](head, tail, cb)

    else
      # Should never happen
      cb("Trying to evaluate a macro that does not exist")


evalMacro = (expr, cb) ->
  do (expr, cb) ->
    head = _.head(expr.args)
    tail = _.tail(expr.args)

    if isMacro(head)
      doEvalMacro(head, tail, cb)
    else
      # If this expression isn't a macro. Then we pass it
      # on to next phase. Which probably is code generation.
      cb(null, expr)

evalMacroRecur = (expr, cb) ->
  do (expr, cb) ->
    head = _.head(expr.args)
    tail = _.tail(expr.args)

    async.map(tail, (element, cb) ->
      if element.type == "EXPR"
        evalMacroRecur(element, cb)
      else
        cb(null, element)
    , (err, expandedTail) ->
      if isMacro(head)
        doEvalMacro(head, expandedTail, cb)
      else
        # If this expression isn't a macro. Then we pass it
        # on to next phase. Which probably is code generation.
        expandedTail.unshift(head)
        cb(null, expandedTail)
    )


macros.require = (head, tail, cb) ->
  do (tail, cb) ->
    name = _.head(tail)
    file = _(tail).tail().head()

    log(1, "Require name: #{name.value}")
    log(1, "Filename: #{file.value}")

    # Create LLVM module
    context = codeGenerators.context(file.value)

    # ##### IMPORTANT #####
    # This is the top level block expressions evaluator.
    # The outer most level in a file.
    # There are no expression sourrounding these expressions
    # This means that when all macros are evaluated, you
    # can perform code generation upon the evaluated result.
    feed = createParser(file.value, (err, expr) ->
      if err?
        log(0, "Err:", err)
        cb(err)
      else
        log(20, "Expr:", expr)
        evalMacro(expr, (err, evaluated) ->
          if err?
            cb(err)
          else
            #codeGenerators.generate(context, evaluated, (err, binary) ->
              #log(0, err)
              #log(0, result))
        ))
    ###### IMPORTANT ENDS ####

    fop.createReadStream(fop.fullSourceFileNameForPath(file.value), createTokenizer(TOK, (err, token) ->
      if err?
        log(0, "Error in require macro", err)
        cb(err)
      else
        if token.type == TOK.EOF.id
          context.module.dump()
          context.module.writeBitcodeToFile(fop.fullBitcodeFileNameForPath(file.value))
          log(1, "Wrote bitcode to #{fop.fullBitcodeFileNameForPath(file.value)}")
          log(1, "EOF")
          cb(null, astTemplates.astForModuleDependency(file.value, name.line, name.column))
        else if !_.contains(TOK.USELESS_TOKENS, token.type)
          feed(token)))


module.exports =
  evalMacro: evalMacro
  builtIn : macros
  user : user
