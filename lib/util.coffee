module.exports =
  parseRef: (value, data) ->
    fileds = value.slice(1).split('.')
    # reuse the value to store data object for refer nested field
    value = data
    for field in fileds
      value = value[field]
    value

  replaceRef: (target, data) ->
    return target if not data
    for key, value of target
      if typeof value is 'object'
        if value.constructor is Array
          for index, item of value
            if typeof item is 'string' and /^\$/.test(value)
              value[index] = @parseRef(item, data)
            else
              @replaceRef(item, data)
        else
          @replaceRef(value, data)
      else if typeof value is 'string' and /^\$/.test(value)
        target[key] = @parseRef value, data
    target