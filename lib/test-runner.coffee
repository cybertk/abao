Mocha = require 'mocha'
async = require 'async'
_ = require 'underscore'


class TestRunner
  constructor: (config) ->
    @accessToken = config.accessToken
    @server = config.server
    @version = config.version
    @options = config.options or {}
    @mocha = new Mocha @options

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

    # Not GET method for this test
    if test.request.method isnt 'GET' and options['read-only']
      suite.addTest new Mocha.Test 'Skip as is not GET method'
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
      # Run actual test case below
      @test.run done
    , {test}

  run: (tests, hooks, callback) ->
    server = @server
    accessToken = @accessToken
    version = @version
    options = @options
    addTestToMocha = @addTestToMocha
    mocha = @mocha

    async.waterfall [
      (callback) ->
        async.each tests, (test, done) ->
          # list tests
          if options.names
            console.log test.name
            return done()

          # Update test.request
          test.request.server = server
          test.request.version = version
          test.request.query =
            access_token: accessToken

          _.extend(test.request.headers, options.header)
          if options.grep and test.request.path.match(options.grep)
            addTestToMocha test, hooks
          else
            addTestToMocha test, hooks
          done()
        , callback
      , # Run mocha
      (callback) ->
        return callback(null, 0) if options.names

        mocha.suite.beforeAll _.bind (done) ->
          @hooks.runBeforeAll done
        , {hooks}
        mocha.suite.afterAll _.bind (done) ->
          @hooks.runAfterAll done
        , {hooks}

        mocha.run (failures) ->
          callback(null, failures)
    ], callback



module.exports = TestRunner
