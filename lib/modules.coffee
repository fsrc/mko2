path      = require("path")
_         = require("lodash")
log       = require("./util").logger(20, 'modules')
fop       = require("./io")
tokenizer = require("./tokenizer")
parser    = require("./parser")

module.exports = (TOK) ->
  do (TOK) ->
    functions = {}

    functions.exprToAst = (expr) ->
      do (expr) ->
        obj = { }

        if expr.type != "EXPR"
          throw "Not valid expression"

        head = _.head(expr.args)
        if head.type == "EXPR"
          console.dir expr
          throw "Can not use expression as identifier [#{head.starts.line}:#{head.starts.column}-#{head.ends.line}:#{head.ends.column}]"

        tail = _.tail(expr.args)
        if tail.length > 1
          obj[head.value] = _.merge(_.map(tail, (arg) ->
            if arg.type == "EXPR"
              functions.exprToObject(arg)
            else
              arg.value)...)
        else
          arg = _.head(tail)
          if arg.type == "EXPR"
            obj[head.value] = functions.exprToObject(arg)
          else
            obj[head.value] = arg.value

        obj

    functions.blockToAst = (block) ->
      _.map(block, (expr) ->
        functions.exprToAst(expr))

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
          cb(null, functions.blockToAst(block)))

      t = tokenizer.create(TOK)
        .onError((err) -> cb(err))
        .onToken((token) -> p.feed(token) if TOK.isUseful(token.type))

      s = fop.createReadStream(moduleFile)
        .onError((err) -> cb(err))
        .onChunk((c) -> t.tokenize(c))
        .onEof(() -> t.tokenize(null))

    functions

