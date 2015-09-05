exports.logger = (filter, id) ->
  do (filter, id) ->
    (prio, texts...) ->
      if prio <=  filter
        console.log("[%s:%s] %s", prio, id, texts...)

