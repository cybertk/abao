util =
  replaceRef: (target, data) ->
    return target if not data
    for key, value of target
      if typeof value is 'object'
        if value.constructor is Array
          for item in value
            util.replaceRef(item, data)
        else
          util.replaceRef(value, data)
      else if typeof value is 'string' and /^\$/.test(value)
        fileds = value.slice(1).split('.')
        # reuse the value to store data object for refer nested field
        value = data
        for field in fileds
          value = value[field]
        target[key] = value
    target

module.exports = util
