###*
# @file Abao class
###

require('source-map-support').install({handleUncaughtExceptions: false})
async = require 'async'
ramlParser = require 'raml-parser'

addHooks = require './add-hooks'
addTests = require './add-tests'
asConfiguration = require './configuration'
hooks = require './hooks'
Runner = require './test-runner'
TestFactory = require './test'

defaultArgs =
  _: []
  options:
    help: true


class Abao
  constructor: (parsedArgs = defaultArgs) ->
    'use strict'
    @configuration = asConfiguration parsedArgs
    @tests = []
    @hooks = hooks

  run: (done) ->
    'use strict'
    config = @configuration
    tests = @tests
    hooks = @hooks

    parseHooks = (callback) ->
      addHooks hooks, config.options.hookfiles, callback
      return # NOTREACHED

    loadRAML = (callback) ->
      if !config.ramlPath
        nofile = new Error 'unspecified RAML file'
        return callback nofile

      ramlParser.loadFile config.ramlPath
        .then (raml) ->
          return callback null, raml
        .catch (err) ->
          return callback err
      return # NOTREACHED

    parseTestsFromRAML = (raml, callback) ->
      if !config.options.server
        if raml.baseUri
          config.options.server = raml.baseUri

      # Inject the JSON refs schemas
      factory = new TestFactory config.options.schemas

      addTests raml, tests, hooks, callback, factory, config.options.sorted
      return # NOTREACHED

    runTests = (callback) ->
      runner = new Runner config.options, config.ramlPath
      runner.run tests, hooks, callback
      return # NOTREACHED

    async.waterfall [
      parseHooks,
      loadRAML,
      parseTestsFromRAML,
      runTests
    ], done
    return



module.exports = Abao

