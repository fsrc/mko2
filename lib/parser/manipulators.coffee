# Helper functions to manage changing an expression object
module.exports =
  createExprArg : (value, type, line, column) ->
    type:type
    line:line
    column:column
    value:value

  # Create a new expression
  createExpr : (line, column, origin, args) ->
    type:"EXPR"
    origin:origin
    starts:
      line:line
      column:column
    ends: null
    args: args ? []

  # Add a part within the expression
  addExprArg : (expr, value, type, line, column) ->
    type:expr.type
    origin:expr.origin
    starts: expr.starts
    ends: null
    args: expr.args.concat(
      type:type, line:line, column:column, value:value)

  addSubExpression : (expr, subexpression) ->
    type:expr.type
    origin:expr.origin
    starts: expr.starts
    ends: null
    args: expr.args.concat(subexpression)


  # Close the expression
  endExpr : (expr, line, column) ->
    type:expr.type
    origin:expr.origin
    starts: expr.starts
    ends:
      line:line
      column:column
    args: expr.args
