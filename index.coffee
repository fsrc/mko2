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
  add : (expr, value, type, line, column) ->
    starts: expr.starts
    args: expr.args.concat(value:value, type:type, line:line, column:column)
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
      # If we have a subparser that needs to be feed
      # then we feed that instead of the parent.
      if state.feeder?
        state.feeder(token)
      else
        if token.data == "("
          if not state.expr?
            state.expr = EXPR.create(token.line, token.column)
          else
            # Create a new subparser to take care of the
            # subexpression
            state.feeder = createParser((err, subexpr) ->
              # When the expression is formulated
              if err?
                cb(err)
              else
                # We extend our current hiearky with the new expression
                state.expr = EXPR.add(
                  state.expr,
                  subexpr,
                  "EXPR",
                  subexpr.starts.line,
                  subexpr.starts.column)
              # Make sure we don't feed the subparser anything else
              state.feeder = null)

            # Feed it with the token that created it
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
            state.expr = EXPR.add(state.expr, token.data, token.type, token.line, token.column)

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

