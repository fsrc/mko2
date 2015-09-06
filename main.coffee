path            = require("path")
_               = require("lodash")

astTemplates    = require("./config/ast-templates")
TOK             = require("./config/tokens")

log             = require("./lib/util").logger(20, 'main')
data            = require("./lib/data")(TOK)
modules         = require("./lib/modules")(TOK)
evaluator       = require("./lib/evaluator")
codeGenerators  = require("./lib/generators")


rootNamespace = 'org.mko2.test'
testFileName = './examples/main'

pp = (obj, linesToPrint) ->
  str = JSON.stringify(obj, null, 2)
  if not linesToPrint?
    str
  else
    lines = str.split('\n')
    _.take(lines, linesToPrint)

bootstrap = (namespace, rootPath, entryModule, cb) ->
  do (namespace, entryModule, rootPath, cb) ->
    #mainFile = path.join(rootPath, entryModule)

    #log(1, "Namespace: #{namespace} root-path: #{rootPath} entry-module: #{entryModule} main-file: #{mainFile}")
    modules.load(namespace, rootPath, entryModule, (err, result) ->
      cb(err, result))

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
      log(0, pp result)
    )
)
