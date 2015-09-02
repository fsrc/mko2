log             = require("./util").logger(20, 'index')
macros          = require("./built-in-macros")

testFileName = './examples/basic'

# Start compiling
macros.builtIn.require(null, [{ value:'main' },{ value:testFileName }], (err, result) ->
  log("Error in main", err) if err?
  log("Result from main", result) if result?
)

