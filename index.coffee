_     = require("lodash")
async = require("async")
llvm  = require("llvm2")
fs    = require("fs")

TOK = require("./tokens")

createTokenizer = require("./tokenizer")
createParser = require("./parser")

testFileName = './examples/basic.mko'


# Simplify opening files / Prefere callbacks instead of promises
createReadStream = (fileName, cb) ->
  do (fileName, cb) ->
    stream = fs.createReadStream(fileName, flags:'r', encoding:'utf8', autoClose:true)
    stream.on('data', (chunk) -> cb(null, chunk))
    stream.on('end', () -> cb(null, [null]))
    stream.on('error', (err) -> cb(err, null))


built_in_macros =
  call: (head, tail) ->
    console.log(tail)
  fun : (head, tail) ->
    name = _.head(tail)
    arity = _.tail(tail)

    console.log(arity)

user_macros = {}

codegen = (expr) ->
  head = _.head(expr.args)
  tail = _.tail(expr.args)

  if _.has(built_in_macros, head.value)
    built_in_macros[head.value](head, tail)

  else if _.has(user_macros, head.value)
    user_macros[head.value](head, tail)

  else
    built_in_macros.call(head, tail)

feed = createParser((err, expr) ->
  if err?
    console.log("Err:")
    console.dir(err)
  else
    console.log("Expr:")
    console.dir(expr)
    console.dir(codegen(expr))
)

createReadStream(testFileName, createTokenizer(TOK, (err, token) ->
  if err?
    console.dir(err)
  else
    # Make sure we only feed the relevant tokens
    # to the parser.
    if !_.contains(TOK.USELESS_TOKENS, token.type)
      feed(token)))

Builder = new llvm.Builder()

