Mocha = require 'mocha'
async = require 'async'
_ = require 'underscore'
generateHooks = require './hooks-generator'

class TestRunner
  constructor: (options) ->
    @server = options.server
    delete options.server
    @options = options
    @mocha = new Mocha options

  addTestToMocha: (test, hooks) =>
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
    title = if test.response.schema then 'Validate response code and body' else 'Validate response code only'
    suite.addTest new Mocha.Test title, _.bind (done) ->
      @test.run done
    , {test}

  run: (tests, hooks, done) ->
    server = @server
    options = @options
    addTestToMocha = @addTestToMocha
    mocha = @mocha
    names = []

    async.waterfall [
      (callback) ->
        async.each tests, (test, done) ->
          # list tests
          if options.names || options['generate-hooks']
            names.push test.name
            return done()

          # none shall pass without...
          return callback(new Error 'no API endpoint specified') if !server

          # Update test.request
          test.request.server = server
          _.extend(test.request.headers, options.header)

          addTestToMocha test, hooks
          done()
        , callback
    , # Write names to console
      (callback) ->
        return callback() if not options.names

        for key, name of names
          console.log name
        callback
    , # Generate hooks skeleton file
      (callback) ->
        return callback() if not options['generate-hooks']

        generateHooks names, 'hooks.js', callback

      , # Run mocha
      (callback) ->
        return callback(null, 0) if options.names or options['generate-hooks']

        mocha.suite.beforeAll _.bind (done) ->
          @hooks.runBeforeAll done
        , {hooks}
        mocha.suite.afterAll _.bind (done) ->
          @hooks.runAfterAll done
        , {hooks}

        mocha.run (failures) ->
          callback(null, failures)
    ], done


module.exports = TestRunner

