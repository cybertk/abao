require('chai').should()

Mocha = require 'mocha'
Test = Mocha.Test
Suite = Mocha.Suite

raml = require 'raml-parser'
tv4 = require 'tv4'


_validatable = (body) ->

  return false if not body

  json = body['application/json']
  return false if not json

  return true if json.example and json.schema
  false


_validate = (body) ->

  example = JSON.parse body['application/json'].example
  schema = JSON.parse body['application/json'].schema
  tv4.validate example, schema


_traverse = (ramlObj, parentUrl, parentSuite) ->

  for i of ramlObj.resources
    resource = ramlObj.resources[i]

    url = parentUrl + resource.relativeUri

    # Generate Test Suite
    suite = Suite.create parentSuite, url

    # Generate Test Cases
    for j of resource.methods

      endpoint = resource.methods[j]
      method = endpoint.method

      # Request
      if not _validatable(endpoint.body)
        suite.addTest new Test "#{method.toUpperCase()} request"
      else
        suite.addTest new Test "#{method.toUpperCase()} request", ->
          true.should.equal _validate endpoint.body

      # Response
      if not endpoint.responses
        suite.addTest new Test "#{method.toUpperCase()} response"

      for status, res of endpoint.responses

        if not _validatable(res.body)
          suite.addTest new Test "#{method.toUpperCase()} response #{status}"
        else
          suite.addTest new Test "#{method.toUpperCase()} response #{status}", ->
            true.should.equal _validate res.body

    _traverse resource, url, parentSuite


generateTests = (source, mocha, callback) ->

  raml.load(source).then (raml) ->

    _traverse raml, '', mocha.suite

    callback()
  , (error) ->
    console.log(error)
    callback()


module.exports = generateTests
