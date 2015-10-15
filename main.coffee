path    = require("path")
_       = require("lodash")

TOK     = require("./config/tokens")

log     = require("./lib/util").logger(20, 'main')
pp      = require("./lib/util").pp
data    = require("./lib/data")(TOK)
modules = require("./lib/modules")(TOK)


bootstrap = (namespace, rootPath, entryModule, cb) ->
  do (namespace, entryModule, rootPath, cb) ->
    modules.load(namespace, rootPath, entryModule, (err, parsed) ->
      cb(err, parsed))

data.load("./examples", (err, result) ->
  if err?
    console.log err
  else
    namespace = result.config['namespace']
    entryModule = result.config['entry-module']
    rootPath = result.config['root-path']

    bootstrap(namespace, rootPath, entryModule, (err, result) ->
      if err?
        log(0, err)
      else
        console.log pp result
    )
)
