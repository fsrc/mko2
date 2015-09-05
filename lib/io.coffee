fs    = require("fs")
path  = require("path")

log   = require("./util").logger(1, 'file-operations')

DEFAULT_SRC_FILENAME_EXTENSION = ".mko"
DEFAULT_BIN_FILENAME_EXTENSION = ".bc"
PACKAGE_FILE = "package.mko"

exports.fullSourceFileNameForPath = (fileName) -> fileName + DEFAULT_SRC_FILENAME_EXTENSION
exports.fullBitcodeFileNameForPath = (fileName) -> fileName + DEFAULT_BIN_FILENAME_EXTENSION


exports.createReadStream = (fileName) ->
  do (fileName) ->
    wrapper = {}
    wrapper.onError = (fn) -> wrapper.error = fn ; wrapper
    wrapper.onChunk = (fn) -> wrapper.chunk = fn ; wrapper
    wrapper.onEof   = (fn) -> wrapper.eof = fn ; wrapper
    wrapper.error = (e) -> e
    wrapper.chunk = (e) -> e
    wrapper.eof = (e) -> e

    stream = fs.createReadStream(fileName, flags:'r', encoding:'utf8', autoClose:true)
    stream.on('data', (chunk) -> wrapper.chunk(chunk))
    stream.on('end', () -> wrapper.eof())
    stream.on('error', (err) -> wrapper.error(err))

    wrapper

cleanUpPath = (str) ->
  path.normalize(path.resolve(str)).replace(/[~\/]+$/, '')

exports.findConfig = (path, cb) ->
  do (path, cb) ->
    clean = cleanUpPath(path)
    file = "#{clean}/#{PACKAGE_FILE}"
    if file == "/#{PACKAGE_FILE}"
      cb("Config not found")
    else
      fs.exists(file, (exists) ->
        if exists
          cb(null, file)
        else
          exports.findConfig(clean + "/..", cb))


