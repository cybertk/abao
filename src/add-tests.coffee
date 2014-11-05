async = require 'async'
_ = require 'underscore'

Test = require './test'


# addTests(raml, tests, [parent], callback)
addTests = (raml, tests, parent, callback) ->

  # Handle 3th optional param
  if _.isFunction(parent)
    callback = parent
    parent = null

  return callback() unless raml.resources

  # Iterate endpoint
  async.each raml.resources, (resource, callback) ->
    path = resource.relativeUri
    params = {}

    # Apply parent properties
    if parent
      path = parent.path + path
      params = _.clone parent.params

    # Setup param
    if resource.uriParameters
      for key, param of resource.uriParameters
        params[key] = param.example

    # In case of issue #8, resource does not define methods
    resource.methods ?= []

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
        if api.body?['application/json']
          test.request.headers['Content-Type'] = 'application/json'
          test.request.body = JSON.parse api.body['application/json']?.example
        test.request.params = params

        # Update test.response
        test.response.status = status
        test.response.schema = res?.body?['application/json']?.schema

        # Update test
        test.name = "#{method} #{path} -> #{status}"

      callback()
    , (err) ->
      return callback(err) if err

      # Recursive
      addTests resource, tests, {path, params}, callback
  , callback


module.exports = addTests
