_     = require("lodash")
async = require("async")
llvm  = require("llvm2")

tokenizer = (stream) ->
  () ->


fs.open('./examples/basic.mko', 'r', tokenizer)
