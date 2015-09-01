_ = require("lodash")

def = require("./tokdef")

TOK = _.mapValues(def, (value, key) ->
  id:key
  def:value.def
  end:value.end
  incl:value.incl
  exto:value.exto)

TOK.ONE_CHAR_TOKENS = _(def)
  .map((value, key) -> id:key, onec:value.onec)
  .filter((value) -> value.onec)
  .pluck("id")
  .value()

TOK.LONG_TOKENS = _(def)
  .map((value, key) -> id:key, onec:value.onec)
  .filter((value) -> !value.onec)
  .pluck("id")
  .value()

TOK.USELESS_TOKENS = _(def)
  .map((value, key) -> id:key, use:value.use)
  .filter((value) -> !value.use)
  .pluck("id")
  .value()


module.exports = TOK
