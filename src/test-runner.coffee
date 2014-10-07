Mocha = require 'mocha'
async = require 'async'
_ = require 'underscore'


class TestRunner
  constructor: (server, options = {}) ->
    @server = server
    @options = options
    @mocha = new Mocha options

  run: (tests, callback) ->
    server = @server
    options = @options
    mocha = @mocha

    async.each tests, (test, callback) ->

      # Generate Test Suite
      suite = Mocha.Suite.create mocha.suite, test.name

      # list tests
      if options.names
        console.log test.name
        return callback()

      # No Response defined
      if !test.response.status or !test.response.schema
        suite.addTest new Mocha.Test 'Skip'
        return callback()

      # Update test.request
      req = test.request
      req.server = server
      _.extend(req.headers, options.header)

      suite.addTest new Mocha.Test 'Validate', _.bind (done) ->
        @test.run done
      , {test}

      callback()

    , (err) ->
      return callback(err) if err
      return callback(null, {}) if options.names

      mocha.run ->
        callback(null, mocha.reporter.stats)


module.exports = TestRunner
