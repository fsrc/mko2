_     = require("lodash")

# Create the tokenizer, we need a state to manage this algorithm
createTokenizer = (cb) ->
  TOK =
    DEL: # Delimiters
      id:"DEL"
      def:(c) -> _.contains(['(',')'], c)
      end:[]
    EOL: # End Of Line
      id:"EOL"
      def:(c) -> _.contains(['\n'], c)
      end:[]
    EOF: # End Of File
      id:"EOF"
      def:(c) -> c == null
      end:[]
    COM: # Comment
      id:"COM"
      def:(c) -> _.contains(['#'], c)
    SPACE: # Blank space
      id:"SPACE"
      def:(c) -> _.contains([' ', '\t'], c)
    IDENT: # Identifier
      id:"IDENT"

  TOK.COM.end   = [TOK.EOL.id, TOK.EOF.id]
  TOK.IDENT.end = [TOK.DEL.id, TOK.EOL.id, TOK.EOF.id, TOK.SPACE.id]
  TOK.SPACE.end = [TOK.DEL.id, TOK.EOL.id, TOK.EOF.id, TOK.COM.id, TOK.IDENT.id]
  TOK.IDENT.def = (c) ->
    not TOK.DEL.def(c) and
    not TOK.SPACE.def(c) and
    not TOK.COM.def(c) and
    not TOK.EOL.def(c) and
    not TOK.EOF.def(c)

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

  tokenize = (state, chunk, cb) ->
    _.reduce(chunk, (state, char) ->
      type = classify(char).id

      if state.token? and not _.contains(TOK[state.token.type].end, type)
        state.token = continueToken(state.token, char)
      else
        if state.token?
          cb(null, endToken(state.token))
          state.token = null

        if type == TOK.DEL.id
          cb(null, createToken(type, char, state.line, state.column))

        else if type == TOK.SPACE.id
          state.token = createToken(type, char, state.line, state.column)

        else if type == TOK.COM.id
          state.token = createToken(type, char, state.line, state.column)

        else if type == TOK.EOL.id
          cb(null, createToken(type, char, state.line, state.column))
          # Add one to the lines
          state.line += 1
          # Reset column to zero, taking into account the increase just
          # before end of loop
          state.column = 0

        else if type == TOK.EOF.id
          cb(null, createToken(type, char, state.line, state.column))

        else
          state.token = createToken(type, char, state.line, state.column)

      # Always increase the column position
      state.column += 1

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
