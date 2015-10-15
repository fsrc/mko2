_ = require("lodash")
node = null

nodeTypes =
  IDENT : (identifier) ->
    do (identifier) ->
      wrapper =
        type:"IDENT"
        value : identifier.value

  EXPR :  (expr) ->
    do (expr) ->
      wrapper =
        type:"EXPR"
        callee : node(_.head(expr.args))
        args : () -> _.map(_.tail(expr.args), node)

  NULL : () ->
    type:"NULL"

node = (node) ->
  do (node) ->
    if node?
      nodeTypes[node.type](node)
    else
      nodeTypes.NULL()


module.exports = node
