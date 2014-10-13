async = require 'async'
_ = require 'underscore'

Test = require './test'


# addTests(raml, tests, [parentUri], callback)
addTests = (raml, tests, parentUri, callback) ->

  # Handle 3th optional param
  if _.isFunction(parentUri)
    callback = parentUri
    parentUri = ''

  return callback() unless raml.resources

  # Iterate endpoint
  async.each raml.resources, (resource, callback) ->
    path = parentUri + resource.relativeUri

    # Iterate response method
    async.each resource.methods, (api, callback) ->
      method = api.method.toUpperCase()

      # Iterate response status
      for status, res of api.responses

        # Append new test to tests
        test = new Test
        tests.push test

        # Update test.request
        test.request.path = path
        test.request.method = method

        # Update test.response
        test.response.status = status
        test.response.schema = res?.body?['application/json']?.schema

        # Update test
        test.name = "#{method} #{path} -> #{status}"

      callback()
    , (err) ->
      return callback(err) if err

      # Recursive
      addTests resource, tests, path, callback
  , callback


module.exports = addTests
