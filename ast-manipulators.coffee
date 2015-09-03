# Helper functions to manage changing an expression object
module.exports =
  createExprArg : (value, type, line, column) ->
    value:value
    type:type
    line:line
    column:column

  # Create a new expression
  createExpr : (line, column, origin, args) ->
    starts:
      line:line
      column:column
      origin:origin
    args: args ? []
    ends: null

  # Add a part within the expression
  addExprArg : (expr, value, type, line, column) ->
    starts: expr.starts
    args: expr.args.concat(
      value:value, type:type, line:line, column:column)
    ends: null

  # Close the expression
  endExpr : (expr, line, column) ->
    starts: expr.starts
    args: expr.args
    ends:
      line:line
      column:column
