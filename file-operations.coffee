fs    = require("fs")
log   = require("./util").logger(1, 'file-operations')

DEFAULT_SRC_FILENAME_EXTENSION = ".mko"
DEFAULT_BIN_FILENAME_EXTENSION = ".bc"

exports.fullSourceFileNameForPath = (fileName) -> fileName + DEFAULT_SRC_FILENAME_EXTENSION
exports.fullBitcodeFileNameForPath = (fileName) -> fileName + DEFAULT_BIN_FILENAME_EXTENSION

# Simplify opening files / Prefere callbacks instead of promises
exports.createReadStream = (fileName, cb) ->
  log(1, "Reading file #{fileName}")
  do (fileName, cb) ->
    stream = fs.createReadStream(fileName, flags:'r', encoding:'utf8', autoClose:true)
    stream.on('data', (chunk) -> cb(null, chunk))
    stream.on('end', () -> cb(null, [null]))
    stream.on('error', (err) -> cb(err, null))

