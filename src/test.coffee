chai = require 'chai'
csonschema = require 'csonschema'
request = require 'request'
_ = require 'underscore'

assert = chai.assert
chai.use(require 'chai-json-schema')

class Test
  constructor: () ->
    @name = ''
    @skip = false

    @request =
      server: ''
      path: ''
      method: 'GET'
      params: {}
      query: {}
      headers: {}

    @response =
      status: ''
      schema: null
      headers: null
      body: null

  url: () ->
    req = @request
    return "#{req.protocol}://#{req.hostname}#{req.path}"

  run: (callback) ->
    url = @request.server + @request.path
    {method, headers} = @request
    {status, schema} = @response
    test = this

    csonschema.parse schema, (err, obj) ->
      options = {url, headers, method}

      request options, (error, response, body) ->
        assert.isNull error
        assert.isNotNull response

        # Status code
        assert.equal response.statusCode, status

        # Body
        assert.isNotNull body
        assert.jsonSchema (JSON.parse body), obj

        # Update @response
        test.response.body = JSON.parse body

        callback()

module.exports = Test
