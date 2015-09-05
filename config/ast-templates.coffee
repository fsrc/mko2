TOK = require("./tokens")
ast = require("../lib/manipulators")

astForModuleDependency = (moduleName, line, column) ->
  ast.createExpr(line, column, moduleName, [
    ast.createExprArg("import", TOK.IDENT.id, line, column),
    ast.createExprArg(moduleName, TOK.IDENT.id, line, column)
  ])

exports.astForModuleDependency = astForModuleDependency
