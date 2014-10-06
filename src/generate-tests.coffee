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

_validatable = (body) ->

  return false if not body

  json = body['application/json']
  return false if not json

  return true if json.example and json.schema
  false


_traverse = (ramlObj, parentUrl, parentSuite, configuration) ->

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

              console.error('ack')
              options =
                url: configuration.server + url
                headers: {}

              console.error('ck', configuration)
              if configuration.options.header.length > 0
                for header in configuration.options.header
                  splitHeader = header.split(':')
                  options.headers[splitHeader[0]] = splitHeader[1]

              request options, (error, response, body) ->
                assert.isNull error
                assert.isNotNull response

                # Status code
                assert.equal response.statusCode, status

                # Body
                assert.isNotNull body
                assert.jsonSchema (JSON.parse body), obj
                done()

          , { schema: res.body['application/json'].schema }

    _traverse resource, url, parentSuite, configuration


generateTests = (source, mocha, configuration, callback) ->

  raml.load(source).then (raml) ->

    _traverse raml, '', mocha.suite, configuration

    callback()
  , (error) ->
    console.log(error)
    callback()


module.exports = generateTests
