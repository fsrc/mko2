log       = require("./util").logger(20, 'modules')
path      = require("path")
_         = require("lodash")
fop       = require("./io")
tokenizer = require("./tokenizer")
parser    = require("./parser")

module.exports = (TOK) ->
  do (TOK) ->
    functions = {}

    functions.load = (namespace, rootPath, moduleName, cb) ->
      fqModuleName = namespace + "/" + moduleName
      moduleFile = fop.fullSourceFileNameForPath(rootPath, moduleName)

      p = parser.create(fqModuleName)
        .onIsOpening((token) -> TOK.DEL.open(token.data))
        .onIsClosing((token) -> TOK.DEL.close(token.data))
        .onIsEof((token) -> token.type == TOK.EOF.id)
        .onError(cb)
        .onEof((block) ->
          log(20, block)
          cb(null, block))

      t = tokenizer.create(TOK)
        .onError((err) -> cb(err))
        .onToken((token) -> p.feed(token) if TOK.isUseful(token.type))

      s = fop.createReadStream(moduleFile)
        .onError((err) -> cb(err))
        .onChunk((c) -> t.tokenize(c))
        .onEof(() -> t.tokenize(null))

    functions

