_     = require("lodash")
pjson = require("prettyjson")

exports.pp = (obj, linesToPrint) ->
  str = pjson.render(obj)
  if not linesToPrint?
    str
  else
    lines = str.split('\n')
    _.take(lines, linesToPrint).join("\n")

exports.strip = (block) ->
  block = [block] if not _.isArray(block)
  result = _.map(block, (expr) ->
    result = _.cloneDeep(expr)
    result.args = _.map(result.args, (arg) -> exports.strip(arg)) if result.args?
    _.omit(result, 'origin', 'starts', 'ends', 'line', 'column'))

  result = result[0] if result.length == 1
  result

exports.logger = (filter, id) ->
  do (filter, id) ->
    (prio, texts...) ->
      if prio <=  filter
        console.log("[%s:%s] %s", prio, id, texts...)

# ######################################################################
# Helper that throws exception if condition isn't truthy
exports.ensure = (expr, truthy, msg) ->
  if not truthy
    console.log expr
    throw msg
