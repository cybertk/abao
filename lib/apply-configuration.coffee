
applyConfiguration = (config) ->

  coerceToArray = (value) ->
    if typeof value is 'string'
      value = [value]
    else if !value?
      value = []
    else if value instanceof Array
      value
    else value

  coerceToDict = (value) ->
    array = coerceToArray value
    @dict = {}

    if array.length > 0
      for item in array
        splitItem = item.split(':')
        @dict[splitItem[0]] = splitItem[1]

    return @dict

  configuration =
    ramlPath: null
    server: null
    options:
      schemas: null
      reporters: false
      reporter: null
      header: null
      names: false
      hookfiles: null
      grep: ''
      invert: false
      'hooks-only': false

  # normalize options and config
  for own key, value of config
    configuration[key] = value

  # coerce some options into an dict
  configuration.options.header = coerceToDict(configuration.options.header)

  # TODO(quanlong): OAuth2 Bearer Token
  if configuration.options.oauth2Token?
    configuration.options.headers['Authorization'] = "Bearer #{configuration.options.oauth2Token}"

  return configuration


module.exports = applyConfiguration

