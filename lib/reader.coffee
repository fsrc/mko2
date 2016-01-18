_ = require("lodash")
node = null

nodeTypes =
  INT : (constant) ->
    do (constant) ->
      wrapper =
        category: "CONST"
        type    : "INT"
        value   : constant.value

  IDENT : (identifier) ->
    do (identifier) ->
      wrapper =
        category: "IDENT"
        value   : identifier.value

  EXPR : (expr) ->
    do (expr) ->
      wrapper =
        category: "EXPR"
        callee  : node(_.head(expr.args))
        args    : _.map(_.tail(expr.args), node)

  NULL : () ->
    type : "NULL"

node = (node) ->
  do (node) ->
    if node?
      if _.has(nodeTypes, node.type)
        nodeTypes[node.type](node)
      else
        throw "[#{node.origin} #{node.line}:#{node.column}] On '#{node.type}' with value '#{node.value}' - The '#{node.type}' type is not recognized by the parser."
    else
      nodeTypes.NULL()


module.exports = node
