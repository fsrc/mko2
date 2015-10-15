path      = require("path")
_         = require("lodash")
log       = require("./util").logger(20, 'modules')
pp        = require("./util").pp
strip     = require("./util").strip
fop       = require("./io")
tokenizer = require("./tokenizer")
parser    = require("./parser")
convert   = require("./llvm")
reader    = require("./reader")

module.exports = (TOK) ->
  do (TOK) ->
    functions = {}
    moduleState = null

    functions.load = (namespace, rootPath, moduleName, cb) ->
      fqModuleName = namespace + "/" + moduleName
      moduleFile = fop.fullSourceFileNameForPath(rootPath, moduleName)

      p = parser.create(fqModuleName)
        .onIsOpening((token) -> TOK.DEL.open(token.data))
        .onIsClosing((token) -> TOK.DEL.close(token.data))
        .onIsEof((token) -> token.type == TOK.EOF.id)
        .onError(cb)
        .onExpression((expr) ->
          console.dir(reader(expr))
          #if expr?
            #moduleState ?= convert.module(fqModuleName)
            #moduleState = convert.exprToAst(moduleState, expr)
        )
        .onEof((block) ->
          #moduleState.llvmModule.dump()
          #moduleState.llvmModule.writeBitcodeToFile(fop.fullBitcodeFileNameForPath(rootPath, moduleName))
          cb(null))

      t = tokenizer.create(TOK)
        .onError((err) -> cb(err))
        .onToken((token) -> p.feed(token) if TOK.isUseful(token.type))

      s = fop.createReadStream(moduleFile)
        .onError((err) -> cb(err))
        .onChunk((c) -> t.tokenize(c))
        .onEof(() -> t.tokenize(null))

    functions

