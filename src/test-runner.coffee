Mocha = require 'mocha'
async = require 'async'
_ = require 'underscore'


class TestRunner
  constructor: (server, options = {}) ->
    @server = server
    @options = options
    @mocha = new Mocha options

  run: (tests, hooks, callback) ->
    server = @server
    options = @options
    mocha = @mocha

    async.each tests, (test, callback) ->

      # list tests
      if options.names
        console.log test.name
        return callback()

      # Generate Test Suite
      suite = Mocha.Suite.create mocha.suite, test.name

      # No Response defined
      if !test.response.status or !test.response.schema
        suite.addTest new Mocha.Test 'Skip'
        return callback()

      # No Hooks for this test
      if not hooks.hasName(test.name) and options['hooks-only']
        suite.addTest new Mocha.Test 'Skip as no hooks defined'
        return callback()

      # Update test.request
      req = test.request
      req.server = server
      _.extend(req.headers, options.header)

      if hooks
        suite.beforeAll _.bind (done) ->
          @hooks.runBefore @test, done
        , {hooks, test}

        suite.afterAll _.bind (done) ->
          @hooks.runAfter @test, done
        , {hooks, test}

      suite.addTest new Mocha.Test 'Validate', _.bind (done) ->
        @test.run done
      , {hooks, test}

      callback()

    , (err) ->
      return callback(err) if err
      return callback(null, {}) if options.names

      mocha.run (failures) ->
        callback(null, failures)


module.exports = TestRunner
