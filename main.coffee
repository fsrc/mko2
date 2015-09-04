_               = require("lodash")
log             = require("./util").logger(1, 'index')
fop             = require("./file-operations")
TOK             = require("./tokens")
tokenizer       = require("./tokenizer")
parser          = require("./parser")
macros          = require("./built-in-macros")
codeGenerators  = require("./code-generators")
astTemplates    = require("./ast-templates")


rootNamespace = 'org.mko2.test'
testFileName = './examples/main'

loadConfig = (startPath, cb) ->
  fop.findConfig(startPath, (err, configFile) ->
    if err?
      cb(err)
    else
      p = parser.create("config")
        .onIsOpening((token) -> TOK.DEL.open(token.data))
        .onIsClosing((token) -> TOK.DEL.close(token.data))
        .onIsEof((token) -> token.type == TOK.EOF.id)
        .onError(cb)
        .onEof((block) -> cb(null, block))
        .onExpression((expr) ->
          macros.evalMacro(result.expr, (err, evaluated) ->
            if err?
              cb(err)
            else
              result.callback(null, evaluated)))

      t = tokenizer.create(TOK)
        .onError((err) -> cb(err))
        .onToken(p.feed)

      s = fop.createReadStream(configFile)
        .onError((err) -> cb(err))
        .onChunk((c) -> t.tokenize(c))
        #.onEof(t.tokenize)
  )


bootstrap = (namespace, mainFile, cb) ->
  do (namespace, mainFile, cb) ->
    log(1, "Namespace: #{namespace} Filename: #{mainFile}")

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
            cb(null)))
    ###### IMPORTANT ENDS ####

    fop.createReadStream(fop.fullSourceFileNameForPath(mainFile), createTokenizer(TOK, (err, token) ->
      if err?
        log(0, "Error in require macro", err)
        cb(err)
      else
        if token.type == TOK.EOF.id
          cb(null)
        else if !_.contains(TOK.USELESS_TOKENS, token.type)
          feed(token)))


# Start compiling
#bootstrap(rootNamespace, testFileName, (err, result) ->
  #log("Error in main", err) if err?
  #log("Result from main", result) if result?)
loadConfig("./examples", (err, result) ->
  if err?
    console.log err
  else
    console.log result)
