###*
# @file Abao class
###

require('source-map-support').install({handleUncaughtExceptions: false})
async = require 'async'
ramlParser = require 'raml-parser'

addTests = require './add-tests'
addHooks = require './add-hooks'
applyConfiguration = require './configuration'
hooks = require './hooks'
options = require './options'
Runner = require './test-runner'
TestFactory = require './test'


class Abao
  constructor: (config) ->
    'use strict'
    @configuration = applyConfiguration config
    @tests = []
    @hooks = hooks

  run: (done) ->
    'use strict'
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
        addTests raml, tests, hooks, callback, factory, config.options.sorted
      ,
      # Run tests
      (callback) ->
        runner = new Runner config.options, config.ramlPath
        runner.run tests, hooks, callback
    ], done



module.exports = Abao
module.exports.options = options

