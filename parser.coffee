
# Helper functions to manage changing an expression object
EXPR =
  # Create a new expression
  create : (line, column) ->
    starts:
      line:line
      column:column
    args: []
    ends: null

  # Add a part within the expression
  add : (expr, value, type, line, column) ->
    starts: expr.starts
    args: expr.args.concat(
      value:value, type:type, line:line, column:column)
    ends: null

  # Close the expression
  end : (expr, line, column) ->
    starts: expr.starts
    args: expr.args
    ends:
      line:line
      column:column


# Construct a closure arond the parser
createParser = (cb) ->
  do (cb) ->
    # Keeps track of current expression and
    # subparser if we are nested
    state = { expr: null, feeder: null }

    # The feeder function takes tokens and
    # emits completed expressions to cb
    feeder = (token) ->

      # If we have a subparser that needs to be feed
      # then we feed that instead of the parent.
      if state.feeder?
        state.feeder(token)
      else
        # Check if the token is a start token
        if token.data == "("
          # If we don't have an expression that we are
          # working on, we create a new one.
          if not state.expr?
            state.expr = EXPR.create(token.line, token.column)
          else
            # Turns out we already have an expression so we
            # create a new subparser to take care of the
            # subexpression
            state.feeder = createParser((err, subexpr) ->
              # If building the expression generates an error
              if err?
                cb(err)
              # Else we completed the subexpression, lets include
              # it in the parent expression.
              else
                # We extend our current hiearky with the new expression
                state.expr = EXPR.add(
                  state.expr,
                  subexpr,
                  "EXPR",
                  subexpr.starts.line,
                  subexpr.starts.column)

              # Make sure we kill the subparser
              state.feeder = null)

            # Feed the new parser with the first token - a parenthesis
            state.feeder(token)

        # If we are closing the expression
        else if token.data == ")"
          # Problems
          if not state.expr?
            cb(msg:"Error: Ending delimiter don't match a starting delimiter", token:token)
          # No problems, let's close the expression and emit the
          # result back to our owner.
          else
            # Close it
            state.expr = EXPR.end(state.expr, token.line, token.column)
            # Emit result
            cb(null, state.expr)
            # Make sure we clean up after us
            state.expr = null

        # This is where we fill the expression with content
        else
          if not state.expr?
            cb(msg:"Error: Identifier outside of expression", token:token)
          else
            # Add items into the list
            state.expr = EXPR.add(state.expr, token.data, token.type, token.line, token.column)

    feeder

module.exports = createParser
