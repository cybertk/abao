async = require 'async'
_ = require 'underscore'

Test = require './test'


addTests = (raml, tests, callback) ->

  return callback() unless raml.resources

  async.each raml.resources, (resource, callback1) ->
  # for i of ramlObj.resources
    async.each resource.methods, (endpoint, callback2) ->
      for status, res of endpoint.responses
        test = new Test
        test.request.path = resource.relativeUri
        test.request.method = endpoint.method.toUpperCase()

        test.response.status = status
        test.response.schema = res.body['application/json'].schema

        test.name = "#{test.request.method} #{test.request.path} -> #{test.response.status}"
        tests.push test

      callback2()
    , (err) ->
      return callback1(err) if err

      addTests resource, tests, callback1
  , callback


module.exports = addTests
