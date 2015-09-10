path      = require("path")
_         = require("lodash")
log       = require("./util").logger(20, 'modules')
pp        = require("./util").pp
strip     = require("./util").strip
fop       = require("./io")
tokenizer = require("./tokenizer")
parser    = require("./parser")
llvm = require("llvm2")

typeMap =
  "int-type" : llvm.Library.LLVMInt64Type

ensureExpr = (expr, truthy, msg) ->
  throw msg if not truthy

convert = {}
convert.function = (moduleState, expr) ->
    lastExpr = _.last(expr.args)
    ensureExpr(expr,
      expr.args.length > 2 and
      expr.args.length < 5,
      "Function type declaration must contain name and list of types")
    ensureExpr(expr,
      lastExpr.type == "EXPR" and
      lastExpr.args.length > 0,
      "Function type must define at least a return type")

    types = _.last(expr.args).args

    retType = typeMap[_.head(types).value]()
    argTypes = _.map(_.tail(types), (type) -> typeMap[type.value]())

    moduleState.types[expr.args[1].value] =
      typeName : "function-type"
      llvmType : new llvm.FunctionType(retType, argTypes, false)

convert.define = (moduleState, expr) ->
    ensureExpr(expr,
      expr.args.length > 3 and
      expr.args.length < 5,
      "Function definition must contain function-type, function-name arity and list of blocks")
    type = moduleState.types[expr.args[1].value]
    varName = expr.args[2].value

    if type.typeName == "function-type"
      console.log type
      console.log varName
      llvmFunction = moduleState.llvmModule.addFunction(varName, type.llvmType, false)
      entryBlock = llvmFunction.appendBasicBlock("entry")

    moduleState

convert.block = (module, declarations, expr) -> null

module.exports = (TOK) ->
  do (TOK) ->
    functions = {}

    functions.exprToAst = (moduleState, expr) ->
      ensureExpr(expr, expr.type == "EXPR", "Not an expression")
      ensureExpr(expr,
        (expr.args[0].type != "EXPR") or
        (expr.args[0].type == "EXPR" and expr.args[0].args?[0] == "meta"),
        "Can't use expression as an identifier")

      if expr.args[0].args?[0] == "meta"
        # Handle meta tag
        moduleState
      else
        ident = expr.args[0].value
        convert[ident](moduleState, expr)

    functions.blockToAst = (moduleState, block) ->
      _.reduce(block, (state, expr) ->
        functions.exprToAst(moduleState, expr)
      , moduleState)

    functions.module = (name, block) ->
      moduleState =
        llvmModule : new llvm.Module(name)
        types : {}
      functions.blockToAst(moduleState, block)

    functions.load = (namespace, rootPath, moduleName, cb) ->
      fqModuleName = namespace + "/" + moduleName
      moduleFile = fop.fullSourceFileNameForPath(rootPath, moduleName)

      p = parser.create(fqModuleName)
        .onIsOpening((token) -> TOK.DEL.open(token.data))
        .onIsClosing((token) -> TOK.DEL.close(token.data))
        .onIsEof((token) -> token.type == TOK.EOF.id)
        .onError(cb)
        .onEof((block) ->
          log(20, '\n' + pp(strip(block[0])))
          types = functions.module(fqModuleName, block)
          log(20, '\n' + pp(types))
          cb(null))

      t = tokenizer.create(TOK)
        .onError((err) -> cb(err))
        .onToken((token) -> p.feed(token) if TOK.isUseful(token.type))

      s = fop.createReadStream(moduleFile)
        .onError((err) -> cb(err))
        .onChunk((c) -> t.tokenize(c))
        .onEof(() -> t.tokenize(null))

    functions

