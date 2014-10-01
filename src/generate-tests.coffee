request = require 'request'
Mocha = require 'mocha'
raml = require 'raml-parser'
chai = require 'chai'
jsonlint = require 'jsonlint'
csonschema = require 'csonschema'
async = require 'async'
_ = require 'underscore'

assert = chai.assert
chai.use(require 'chai-json-schema')

Test = Mocha.Test
Suite = Mocha.Suite

i = 0

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


_traverse = (ramlObj, parentUrl, parentSuite, server) ->

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
      # if not _validatable(endpoint.body)
      #   suite.addTest new Test "#{method.toUpperCase()} request"
      # else
      #   suite.addTest new Test "#{method.toUpperCase()} request", ->
      #     true.should.equal _validate endpoint.body

      # Response
      if not endpoint.responses
        suite.addTest new Test "#{method.toUpperCase()} response"

      for status, res of endpoint.responses

        if not _validatable(res.body)
          suite.addTest new Test "#{method.toUpperCase()} response #{status}"
        else
          suite.addTest new Test "#{method.toUpperCase()} response #{status}",  _.bind (done) ->
            schema = this.schema

            csonschema.parse schema, (err, obj) ->

              # true.should.equal _validate res.body
              request server + url, (error, response, body) ->
                assert.isNull error
                assert.isNotNull response

                # Status code
                assert.equal response.statusCode, status

                # Body
                assert.isNotNull body
                assert.jsonSchema (JSON.parse body), obj
                done()

          , { schema: res.body['application/json'].schema }

    _traverse resource, url, parentSuite, server


generateTests = (source, mocha, server, callback) ->

  raml.load(source).then (raml) ->

    _traverse raml, '', mocha.suite, server

    callback()
  , (error) ->
    console.log(error)
    callback()


module.exports = generateTests
