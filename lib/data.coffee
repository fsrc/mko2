log       = require("./util").logger(20, 'data')
path      = require("path")
_         = require("lodash")
fop       = require("./io")
tokenizer = require("./tokenizer")
parser    = require("./parser")

module.exports = (TOK) ->
  do (TOK) ->
    functions = {}

    functions.exprToObject = (expr) ->
      do (expr) ->
        obj = { }

        if expr.type != "EXPR"
          throw "Not valid expression"

        head = _.head(expr.args)
        if head.type == "EXPR"
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

    functions.objectToExpr = (expr) ->

    functions.blockToObjects = (block) ->
      _.map(block, (expr) ->
        functions.exprToObject(expr))

    functions.objectsToBlock = (block) ->


    functions.load = (startPath, cb) ->
      fop.findConfig(startPath, (err, configFile) ->
        if err?
          cb(err)
        else
          p = parser.create("config")
            .onIsOpening((token) -> TOK.DEL.open(token.data))
            .onIsClosing((token) -> TOK.DEL.close(token.data))
            .onIsEof((token) -> token.type == TOK.EOF.id)
            .onError(cb)
            .onEof((block) ->
              config = functions.blockToObjects(block)[0]
              config.config['root-path'] = path.dirname(configFile)
              cb(null, config))

          t = tokenizer.create(TOK)
            .onError((err) -> cb(err))
            .onToken((token) -> p.feed(token) if TOK.isUseful(token.type))

          s = fop.createReadStream(configFile)
            .onError((err) -> cb(err))
            .onChunk((c) -> t.tokenize(c))
            .onEof(() -> t.tokenize(null)))

    functions
