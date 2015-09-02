_     = require("lodash")
async = require("async")
llvm  = require("llvm2")
fs    = require("fs")
do_log = require("./util").log

log = (texts...) -> do_log('index', texts...)

TOK = require("./tokens")

DEFAULT_FILENAME_EXTENSION = ".mko"

createTokenizer = require("./tokenizer")
createParser = require("./parser")

testFileName = './examples/basic'


fullFileNameForPath = (fileName) ->
  fileName + DEFAULT_FILENAME_EXTENSION

# Simplify opening files / Prefere callbacks instead of promises
createReadStream = (fileName, cb) ->
  log("Reading file #{fileName}")
  do (fileName, cb) ->
    stream = fs.createReadStream(fileName, flags:'r', encoding:'utf8', autoClose:true)
    stream.on('data', (chunk) -> cb(null, chunk))
    stream.on('end', () -> cb(null, [null]))
    stream.on('error', (err) -> cb(err, null))

built_in_macros = {}
user_macros = {}

codegen = (expr, cb) ->
  head = _.head(expr.args)
  tail = _.tail(expr.args)

  if _.has(built_in_macros, head.value)
    built_in_macros[head.value](head, tail, cb)

  else if _.has(user_macros, head.value)
    user_macros[head.value](head, tail, cb)

  else
    built_in_macros.call(head, tail, cb)

built_in_macros.require = (head, tail, cb) ->
  do (tail, cb) ->
    name = _.head(tail)
    file = _(tail).tail().head()

    log("Require name: #{name.value}")
    log("Filename: #{file.value}")

    feed = createParser((err, expr) ->
      if err?
        log("Err:")
        console.dir(err)
      else
        log("Expr:")
        console.dir(expr)
        codegen(expr, (err, result) ->
          console.dir(result)))

    createReadStream(fullFileNameForPath(file.value), createTokenizer(TOK, (err, token) ->
      if err?
        log("Error in require macro")
        log(err)
      else
        if token.type == TOK.EOF
          log("EOF")
        else if !_.contains(TOK.USELESS_TOKENS, token.type)
          feed(token)))

built_in_macros.call = (name, args, cb) ->
  log("Call name: #{name.value}")
  log(args)

built_in_macros.fun = (head, tail, cb) ->
  name = _.head(tail)
  arity = _(tail).tail().head()
  body = _(tail).tail().tail().value()

  log("Fun name: #{name.value}")
  log("Arity")
  log(arity)
  log("Body")
  log(body)

built_in_macros.export = (head, tail) ->



# Start compiling
built_in_macros.require(null, [{ value:'main' },{ value:testFileName }])

