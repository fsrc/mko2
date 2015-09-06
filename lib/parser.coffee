_ = require("lodash")
ast = require("./manipulators")


# Construct a closure around the parser
create = (moduleName) ->
  do (moduleName) ->
    log = require("./util").logger(0, "parser[#{moduleName}]")
    # Keeps track of current expression and
    # subparser if we are nested
    state = { expr: null, feeder: null, block: [] }

    # The feeder function takes tokens and
    # emits completed expressions to wrapper.expression
    wrapper = {}
    wrapper.onError      = (fn) -> wrapper.error = fn ; wrapper
    wrapper.onExpression = (fn) -> wrapper.expression = fn ; wrapper
    wrapper.onEof        = (fn) -> wrapper.eof = fn ; wrapper
    wrapper.onIsOpening  = (fn) -> wrapper.isOpening = fn ; wrapper
    wrapper.onIsClosing  = (fn) -> wrapper.isClosing = fn ; wrapper
    wrapper.onIsEof      = (fn) -> wrapper.isEof = fn ; wrapper

    wrapper.error = (a) -> a
    wrapper.expression = (a) -> a
    wrapper.eof = (a) -> a
    wrapper.isOpening = (a) -> wrapper.error("isOpening must be implemented")
    wrapper.isClosing = (a) -> wrapper.error("isClosing must be implemented")
    wrapper.isEof = (a) -> wrapper.error("isEof must be implemented")

    wrapper.feed = (token) ->
      log(20, "got token", token)

      # If we have a subparser that needs to be feed
      # then we feed that instead of the parent.
      if state.feeder?
        log(20, "in sub state")
        state.feeder.feed(token)
      else
        # Check if the token is a start token
        if wrapper.isOpening(token)
          # If we don't have an expression that we are
          # working on, we create a new one.
          if not state.expr?
            log(20, "creating state")
            state.expr = ast.createExpr(token.line, token.column, moduleName)
          else
            log(20, "creating sub state")
            # Turns out we already have an expression so we
            # create a new subparser to take care of the
            # subexpression
            state.feeder = create(moduleName+" >")
              .onIsOpening(wrapper.isOpening)
              .onIsClosing(wrapper.isClosing)
              .onIsEof(wrapper.isEof)
              .onError((expr) ->
                # Pass on error
                wrapper.error(err)
                # Make sure we kill the subparser
                state.feeder = null)
              .onExpression((subexpr) ->
                log(20, subexpr)
                # We extend our current hiearky with the new expression
                state.expr = ast.addSubExpression(state.expr, subexpr)

                # Make sure we kill the subparser
                state.feeder = null)

            # Feed the new parser with the first token - a parenthesis
            log(20, token)
            state.feeder.feed(token)

        # If we are closing the expression
        else if wrapper.isClosing(token)
          # Problems
          if not state.expr?
            log(0, "error not balanced parenthesis")
            wrapper.error(msg:"Error: Ending delimiter don't match a starting delimiter", token:token)
          # No problems, let's close the expression and emit the
          # result back to our owner.
          else
            log(20, "closing expression")
            # Close it
            state.expr = ast.endExpr(state.expr, token.line, token.column)

            state.block.push(state.expr)
            # Bubble
            wrapper.expression(state.expr)
            # Make sure we clean up after us
            state.expr = null

        # End of file
        else if wrapper.isEof(token)
          log(20, "end of file")
          wrapper.expression(null)
          wrapper.eof(state.block)
        # This is where we fill the expression with content
        else
          if not state.expr?
            log(20, "identifier outside of expression")
            wrapper.error(msg:"Error: Identifier outside of expression", token:token)
          else
            log(20, "adding argument")
            # Add items into the list
            state.expr = ast.addExprArg(state.expr, token.data, token.type, token.line, token.column)
            log(20, JSON.stringify(state.expr))

    wrapper


module.exports =
  create:create
