_               = require("lodash")
log             = require("./lib/util").logger(20, 'index')
fop             = require("./lib/io")
tokenizer       = require("./lib/tokenizer")
parser          = require("./lib/parser")
evaluator       = require("./lib/evaluator")
codeGenerators  = require("./lib/generators")
TOK             = require("./config/tokens")
astTemplates    = require("./config/ast-templates")


rootNamespace = 'org.mko2.test'
testFileName = './examples/main'

pp = (obj, linesToPrint) ->
  str = JSON.stringify(obj, null, 2)
  if not linesToPrint?
    str
  else
    lines = str.split('\n')
    _.take(lines, linesToPrint)


convert = {}

convert.exprToObject = (expr) ->
  do (expr) ->
    obj = { }

    if expr.type != "EXPR"
      throw "Not valid expression"

    head = _.head(expr.args)
    if head.type == "EXPR"
      throw "Can not use expression as identifier"

    tail = _.tail(expr.args)
    if tail.length > 1
      obj[head.value] = _.map(tail, (arg) ->
        if arg.type == "EXPR"
          convert.exprToObject(arg)
        else
          arg.value)
    else
      arg = _.head(tail)
      if arg.type == "EXPR"
        obj[head.value] = convert.exprToObject(arg)
      else
        obj[head.value] = arg.value

    obj

convert.objectToExpr = (expr) ->

convert.blockToObjects = (block) ->
  _.map(block, (expr) ->
    convert.exprToObject(expr))

convert.objectsToBlock = (block) ->


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
        .onEof((block) ->
          cb(null, convert.blockToObjects(block)))

      t = tokenizer.create(TOK)
        .onError((err) -> cb(err))
        .onToken((token) -> p.feed(token) if TOK.isUseful(token.type))

      s = fop.createReadStream(configFile)
        .onError((err) -> cb(err))
        .onChunk((c) -> t.tokenize(c))
        .onEof(() -> t.tokenize(null)))


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
    console.log pp result
)
