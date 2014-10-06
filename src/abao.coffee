fs = require 'fs'

Mocha = require 'mocha'
generateTests = require './generate-tests'

options = require './options'

coerceToArray = (value) ->
    if typeof value is 'string'
      value = [value]
    else if !value?
      value = []
    else if value instanceof Array
      value
    else value

class Abao
  constructor: (config) ->
    @configuration = config

  run: (callback) ->
    config = @configuration

    config.options.header = coerceToArray(config.options.header)

    fs.readFile config.ramlPath, 'utf8', (loadingError, data) ->
      return callback(loadingError, {}) if loadingError

      mocha = new Mocha config.options
      generateTests data, mocha, config, ->
        mocha.run ->
          callback(null, mocha.reporter.stats)


module.exports = Abao
module.exports.options = options
