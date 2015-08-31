_     = require("lodash")

# Create the tokenizer, we need a state to manage this algorithm
createTokenizer = (cb) ->
  # Define what makes different tokens
  isDEL   = (c) -> _.contains(['(',')'], c)
  isSPACE = (c) -> _.contains([' ', '\t'], c)
  isCOM   = (c) -> _.contains(['#'], c)
  isEOL   = (c) -> _.contains(['\n'], c)
  isEOF   = (c) -> c == null
  #isIDENT = (c) -> not isDEL(c) and not isSPACE(c) and not isCOM(c) and not isEOL(c) and not isEOF(c)

  classify = (c) ->
    return TOK_DEL   if isDEL(c)
    return TOK_SPACE if isSPACE(c)
    return TOK_EOL   if isEOL(c)
    return TOK_COM   if isCOM(c)
    return TOK_EOF   if isEOF(c)
    return TOK_IDENT

  # Name tokens
  TOK_DEL   = "DEL"
  TOK_SPACE = "SPACE"
  TOK_COM   = "COM"
  TOK_EOL   = "EOL"
  TOK_EOF   = "EOF"
  TOK_IDENT = "IDENT"

  TOK_DEL_END   = []
  TOK_SPACE_END = [TOK_DEL, TOK_EOL, TOK_EOF, TOK_COM, TOK_IDENT]
  TOK_EOL_END   = []
  TOK_EOF_END   = []
  TOK_COM_END   = [TOK_EOL, TOK_EOF]
  TOK_IDENT_END = [TOK_DEL, TOK_EOL, TOK_EOF, TOK_SPACE]


  # Helper functions that manipulate a token
  createToken = (type, data, untilType, line, column) ->
    type   : type
    data   : data
    line   : line
    column : column
    length : data?.length ? 0
    untilType : untilType

  continueToken = (token, data) ->
    type   : token.type
    data   : token.data + data
    line   : token.line
    column : token.column
    length : token.length + data.length
    untilType : token.untilType

  endToken = (token) ->
    type   : token.type
    data   : token.data
    line   : token.line
    column : token.column
    length : token.length
    untilType : token.untilType

  tokenize = (state, chunk, cb) ->
    _.reduce(chunk, (state, char) ->
      type = classify(char)

      if state.token? and not _.contains(state.token.untilType, type)
        state.token = continueToken(state.token, char)
      else
        if state.token?
          cb(null, endToken(state.token))
          state.token = null

        if type == TOK_DEL
          cb(null, createToken(type, char, TOK_DEL_END, state.line, state.column))

        else if type == TOK_SPACE
          state.token = createToken(type, char, TOK_SPACE_END, state.line, state.column)

        else if type == TOK_COM
          state.token = createToken(type, char, TOK_COM_END, state.line, state.column)

        else if type == TOK_EOL
          cb(null, createToken(type, char, TOK_EOL_END, state.line, state.column))

        else if type == TOK_EOF
          cb(null, createToken(type, char, TOK_EOF_END, state.line, state.column))

        else
          state.token = createToken(type, char, TOK_IDENT_END, state.line, state.column)

      # Make sure we return state
      state
    , state)

  # Create a state
  do (cb) ->
    # Closed variables for tokenizer
    state = {
      line   : 1
      column : 1
      token  : null
    }

    # Actual tokenizer

    # Function that is returned to the caller
    (err, chunk) ->
      if err?
        cb(err)
      else
        state = tokenize(state, chunk, cb)

module.exports = createTokenizer
