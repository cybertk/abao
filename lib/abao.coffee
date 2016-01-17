sms = require("source-map-support").install({handleUncaughtExceptions: false})
raml = require 'raml-parser'
async = require 'async'
chai = require 'chai'

options = require './options'
addTests = require './add-tests'
addCases = require './add-cases'
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

    # init the test factory to inject the json refs schemas
    factory = new TestFactory(config.options.schemas)

    async.waterfall [
      # Load RAML
      (callback) ->
        raml.loadFile(config.ramlPath).then (raml) ->
          config.version = raml.version
          callback(null, raml)
        , callback
      ,
      (raml, callback) ->
        # Parse tests from RAML
        addTests raml, tests, callback, factory
        # Add cases configuration from test folder
        addCases '', raml, tests, callback, factory
      ,
      # Parse hooks
      (callback) ->
        addHooks hooks, config.options.hookfiles
        callback()
      ,
      # Run tests
      (callback) ->
        runner = new Runner config
        runner.run tests, hooks, callback
    ], done


module.exports = Abao
module.exports.options = options
