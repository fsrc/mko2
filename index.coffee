_     = require("lodash")
async = require("async")
#llvm  = require("llvm2")
fs    = require("fs")

createTokenizer = require("./tokenizer")

testFileName = './examples/basic.mko'



# Simplify opening files
createReadStream = (fileName, cb) ->
  do (fileName, cb) ->
    stream = fs.createReadStream(fileName, flags:'r', encoding:'utf8', autoClose:true)
    stream.on('data', (chunk) -> cb(null, chunk))
    stream.on('end', () -> cb(null, [null]))
    stream.on('error', (err) -> cb(err, null))


createReadStream(testFileName, createTokenizer((err, token) ->
  if err?
    console.dir(err)
  else
    console.log(token)
))

