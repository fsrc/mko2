_               = require("lodash")
log             = require("./util").logger(1, 'index')
macros          = require("./built-in-macros")
fop             = require("./file-operations")
TOK             = require("./tokens")
createTokenizer = require("./tokenizer")
createParser    = require("./parser")
codeGenerators  = require("./code-generators")
astTemplates    = require("./ast-templates")

rootNamespace = 'org.mko2.test'
testFileName = './examples/main'

bootstrap = (namespace, mainFile, cb) ->
  do (namespace, mainFile, cb) ->
    log(1, "Namespace: #{namespace} Filename: #{mainFile}")

    # Create LLVM module
    context = codeGenerators.context(namespace)

    # ##### IMPORTANT #####
    # This is the top level block expressions evaluator.
    # The outer most level in a file.
    # There are no expression sourrounding these expressions
    # This means that when all macros are evaluated, you
    # can perform code generation upon the evaluated result.
    feed = createParser(mainFile, (err, expr) ->
      if err?
        log(0, "Err:", err)
        cb(err)
      else
        log(20, "Expr:", expr)
        macros.evalMacro(expr, (err, evaluated) ->
          if err?
            cb(err)
          else
            log(10, "Generating code")
            #codeGenerators.generate(context, evaluated, (err, binary) ->
              #log(0, err)
              #log(0, result))
        ))
    ###### IMPORTANT ENDS ####

    fop.createReadStream(fop.fullSourceFileNameForPath(mainFile), createTokenizer(TOK, (err, token) ->
      if err?
        log(0, "Error in require macro", err)
        cb(err)
      else
        if token.type == TOK.EOF.id
          context.module.dump()
          context.module.writeBitcodeToFile(fop.fullBitcodeFileNameForPath(mainFile))
          log(1, "Wrote bitcode to #{fop.fullBitcodeFileNameForPath(mainFile)}")
          log(1, "EOF")
          cb(null, astTemplates.astForModuleDependency(mainFile, 0, 0))
        else if !_.contains(TOK.USELESS_TOKENS, token.type)
          feed(token)))


# Start compiling
bootstrap(rootNamespace, testFileName, (err, result) ->
  log("Error in main", err) if err?
  log("Result from main", result) if result?)

