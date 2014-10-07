Mocha = require 'mocha'
generateTests = require './generate-tests'
options = require './options'
raml = require 'raml-parser'

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

    chai.tv4.addSchema(id, json) for id, json of config.refs if config.refs

    raml.loadFile(config.ramlPath)
    .then (raml) ->
      mocha = new Mocha config.options
      generateTests raml, mocha, config
      return callback(null, {}) if configuration.options.names

      mocha.run ->
        callback(null, mocha.reporter.stats)

    , (error) ->
      return callback(error, {})


module.exports = Abao
module.exports.options = options
