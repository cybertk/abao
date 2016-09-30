sms = require("source-map-support").install({handleUncaughtExceptions: false})
ramlParser = require 'raml-parser'
async = require 'async'

options = require './options'
addTests = require './add-tests'
TestFactory = require './test'
addHooks = require './add-hooks'
Runner = require './test-runner'
applyConfiguration = require './apply-configuration'
hooks = require './hooks'


class Abao
  constructor: (config) ->
    @configuration = applyConfiguration(config)
    @tests = []
    @hooks = hooks

  run: (done) ->
    config = @configuration
    tests = @tests
    hooks = @hooks

    # Inject the JSON refs schemas
    factory = new TestFactory(config.options.schemas)

    async.waterfall [
      # Parse hooks
      (callback) ->
        addHooks hooks, config.options.hookfiles
        callback()
      ,
      # Load RAML
      (callback) ->
        ramlParser.loadFile(config.ramlPath).then (raml) ->
          callback(null, raml)
        , callback
      ,
      # Parse tests from RAML
      (raml, callback) ->
        if !config.options.server
          if raml.baseUri
            config.options.server = raml.baseUri
        addTests raml, tests, hooks, callback, factory
      ,
      # Run tests
      (callback) ->
        runner = new Runner config.options, config.ramlPath
        runner.run tests, hooks, callback
    ], done


module.exports = Abao
module.exports.options = options

