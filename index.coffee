_     = require("lodash")
async = require("async")
llvm  = require("llvm2")
fs    = require("fs")

createTokenizer = require("./tokenizer")
TOK = require("./tokens")

testFileName = './examples/basic.mko'


# Simplify opening files / Prefere callbacks instead of promises
createReadStream = (fileName, cb) ->
  do (fileName, cb) ->
    stream = fs.createReadStream(fileName, flags:'r', encoding:'utf8', autoClose:true)
    stream.on('data', (chunk) -> cb(null, chunk))
    stream.on('end', () -> cb(null, [null]))
    stream.on('error', (err) -> cb(err, null))


EXPR =
  create : (line, column) ->
    starts:
      line:line
      column:column
    args: []
    ends: null
  add : (expr, identifier, line, column) ->
    starts: expr.starts
    args: expr.args.concat(ident:identifier, line:line, column:column)
    ends: null
  end : (expr, line, column) ->
    starts: expr.starts
    args: expr.args
    ends:
      line:line
      column:column


createParser = (cb) ->
  do (cb) ->
    state = { expr: null, feeder: null }
    feeder = (token) ->
      if state.feeder?
        feeder(token)
      else
        if token.data == "("
          if not state.expr?
            state.expr = EXPR.create(token.line, token.column)
          else
            state.feeder = createParser((err, subexpr) ->
              if err?
                cb(err)
              EXPR.add(state.expr, subexpr)
              state.feeder = null)
            state.feeder(token)

        else if token.data == ")"
          if not state.expr?
            cb(msg:"Error: Ending delimiter don't match a starting delimiter", token:token)
          else
            state.expr = EXPR.end(state.expr, token.line, token.column)
            cb(null, state.expr)
            state.expr = null

        else
          if not state.expr?
            cb(msg:"Error: Identifier outside of expression", token:token)
          else
            state.expr = EXPR.add(state.expr, token.data, token.line, token.column)

    feeder

feed = createParser((err, expr) ->
  if err?
    console.log("Err:")
    console.dir(err)
  console.log("Expr:")
  console.dir(expr)
  )

createReadStream(testFileName, createTokenizer((err, token) ->
  if err?
    console.dir(err)
  else
    if token.type != TOK.SPACE.id and
    token.type != TOK.EOL.id and
    token.type != TOK.EOF.id and
    token.type != TOK.COM.id
      feed(token)
))

