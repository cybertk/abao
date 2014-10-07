raml = require 'raml-parser'
async = require 'async'
chai = require 'chai'

options = require './options'
addTests = require './add-tests'
Runner = require './test-runner'
applyConfiguration = require './apply-configuration'


class Abao
  constructor: (config) ->
    @configuration = applyConfiguration(config)

  run: (callback) ->
    config = @configuration
    tests = []

    async.waterfall [
      # Load RAML
      (callback) ->
        raml.loadFile(config.ramlPath).then (raml) ->
          callback(null, raml)
        , callback
      ,
      # Parse tests from RAML
      (raml, callback) ->
        addTests raml, tests, callback
      ,
      # Run tests
      (callback) ->
        runner = new Runner config.server, config.options
        runner.run tests, callback
    ], callback


module.exports = Abao
module.exports.options = options
