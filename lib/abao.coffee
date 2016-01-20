sms = require("source-map-support").install({handleUncaughtExceptions: false})
raml = require 'raml-parser'
async = require 'async'
chai = require 'chai'
fs = require 'fs'

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

    # init the test factory to inject the json refs schemas
    factory = new TestFactory(config.options.schemas)

    async.waterfall [
      # Load configuration
      (callback) ->
        fs.readFile(config.configPath, 'utf8' ,(err, data) ->
          try
            data = JSON.parse data
            for key, value of data
              config[key] = value
            callback(err)
          catch err
            console.error 'Config file is not a valid JSON file'
            callback(err)
        )
      ,
      # Load RAML
      (callback) ->
        raml.loadFile(config.ramlPath).then (raml) ->
          # Use the version definition in RAML
          config.version = raml.version
          callback(null, raml)
        , callback
      ,
      (raml, callback) ->
        # Parse tests from RAML and cases definition
        addTests raml, tests, callback, factory, config.baseCaseFolder
      ,
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
