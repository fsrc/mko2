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


feed = createParser((err, expr) ->
  if err?
    console.log("Err:")
    console.dir(err)
  else
    console.log("Expr:")
    console.dir(expr))

createReadStream(testFileName, createTokenizer((err, token) ->
  if err?
    console.dir(err)
  else
    # Make sure we only feed the relevant tokens
    # to the parser.
    if !_.contains(TOK.USELESS_TOKENS, token.type)
      feed(token)))
