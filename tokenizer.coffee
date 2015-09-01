_     = require("lodash")
TOK   = require("./tokens")

classify = (c) -> _.find(TOK, (def, name) -> def.def(c))
#
# Helper functions that manipulate a token
createToken = (type, data, line, column) ->
  type   : type
  data   : data
  line   : line
  column : column
  length : data?.length ? 0

continueToken = (token, data) ->
  type   : token.type
  data   : token.data + data
  line   : token.line
  column : token.column
  length : token.length + (data?.length ? 0)

endToken = (token) ->
  type   : token.type
  data   : token.data
  line   : token.line
  column : token.column
  length : token.length

# Tests if char is the end of the state token
isEnding = (stateType, currType, char) ->
  endsWith = TOK[stateType].end
  # If we don't have any ends with characters
  # make sure we only keep going while getting valid
  # characters
  if _.isEmpty(endsWith)
    !TOK[stateType].def(char)
  else
    # Otherwise we check the endsWith characters
    _.contains(endsWith, currType)

# Figure out what sort of token to create. Then create that.
createTokenForType = (type, char, line, column, cb) ->
  # Single char tokens
  if _.contains(TOK.ONE_CHAR_TOKENS, type)
    cb(null, createToken(type, char, line, column))
    null

  # Take care of the longer tokens
  else if _.contains(TOK.LONG_TOKENS, type)
    createToken(type, char, line, column)

  # Everything else is part of a Identifier token
  else
    createToken(type, char, line, column)

# The actual tokenizer routine
tokenize = (state, chunk, cb) ->
  _.reduce(chunk, (state, char) ->
    type = classify(char).id

    # If we have a state token and it doesn't end with what
    # character we just got
    if state.token? and not isEnding(state.token.type, type, char)
      # Continue build that token
      state.token = continueToken(state.token, char)

    else
      # If we got the end char of the current state.token
      if state.token?
        # Is the token inclusive? Then eat the new char too
        if TOK[state.token.type].incl
          state.token = continueToken(state.token, char)
          cb(null, endToken(state.token))
          state.token = null
        else
          # Not inclusive, just end the token
          cb(null, endToken(state.token))
          state.token = null
          # This code should be executed unless it's an inclusive
          # token being built
          state.token = createTokenForType(type, char, state.line, state.column, cb)
      else
        state.token = createTokenForType(type, char, state.line, state.column, cb)

    if type == TOK.EOL.id
      # Add one to the lines
      state.line += 1
      # Reset column to zero, taking into account the increase just
      # before end of loop
      state.column = 1
    else
      # Always increase the column position
      state.column += 1

    # Make sure we return state
    state
  , state)

# Create the tokenizer, we need a state to manage this algorithm
createTokenizer = (cb) ->
  # Create a state
  do (cb) ->
    # Closed variables for tokenizer
    state = {
      line   : 1
      column : 1
      token  : null
    }

    # Function that is returned to the caller
    (err, chunk) ->
      if err?
        cb(err)
      else
        # Feed the tokenizer and keep the state until
        # next round
        state = tokenize(state, chunk, cb)

module.exports = createTokenizer
