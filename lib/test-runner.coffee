###*
# @file TestRunner class
###

async = require 'async'
Mocha = require 'mocha'
path = require 'path'
# TODO(proebuck): Replace underscore module with Lodash; ensure compatibility
_ = require 'underscore'

generateHooks = require './generate-hooks'


class TestRunner
  constructor: (options, ramlFile) ->
    'use strict'
    @server = options.server
    delete options.server
    @mocha = new Mocha options.mocha
    delete options.mocha
    @options = options
    @ramlFile = ramlFile

  addTestToMocha: (test, hooks) =>
    'use strict'
    mocha = @mocha
    options = @options

    # Generate Test Suite
    suite = Mocha.Suite.create mocha.suite, test.name

    # No Response defined
    if !test.response.status
      suite.addTest new Mocha.Test 'Skip as no response code defined'
      return

    # No Hooks for this test
    if not hooks.hasName(test.name) and options['hooks-only']
      suite.addTest new Mocha.Test 'Skip as no hooks defined'
      return

    # Test skipped in hook file
    if hooks.skipped(test.name)
      suite.addTest new Mocha.Test 'Skipped in hooks'
      return

    # Setup hooks
    if hooks
      suite.beforeAll _.bind (done) ->
        @hooks.runBefore @test, done
      , {hooks, test}

      suite.afterAll _.bind (done) ->
        @hooks.runAfter @test, done
      , {hooks, test}

    # Setup test
    # Vote test name
    title = if test.response.schema
              'Validate response code and body'
            else
              'Validate response code only'
    suite.addTest new Mocha.Test title, _.bind (done) ->
      @test.run done
    , {test}

  run: (tests, hooks, done) ->
    'use strict'
    server = @server
    options = @options
    addTestToMocha = @addTestToMocha
    mocha = @mocha
    ramlFile = path.basename @ramlFile
    names = []

    async.waterfall [
      (callback) ->
        async.each tests, (test, cb) ->
          if options.names || options['generate-hooks']
            # Save test names for use by next step
            names.push test.name
            return cb()

          # None shall pass without...
          return callback(new Error 'no API endpoint specified') if !server

          # Update test.request
          test.request.server = server
          _.extend(test.request.headers, options.header)

          addTestToMocha test, hooks
          cb()
        , callback
      , # Handle options that don't run tests
      (callback) ->
        if options['generate-hooks']
          # Generate hooks skeleton file
          generateHooks names, ramlFile, options.template, done
        else if options.names
          # Write names to console
          console.log name for name in names
          return done(null, 0)
        else
          return callback()
      , # Run mocha
      (callback) ->
        mocha.suite.beforeAll _.bind (done) ->
          @hooks.runBeforeAll done
        , {hooks}
        mocha.suite.afterAll _.bind (done) ->
          @hooks.runAfterAll done
        , {hooks}

        mocha.run (failures) ->
          return callback(null, failures)
    ], done



module.exports = TestRunner

