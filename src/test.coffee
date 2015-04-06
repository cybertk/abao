chai = require 'chai'
request = require 'request'
_ = require 'underscore'
async = require 'async'

assert = chai.assert
chai.use(require 'chai2-json-schema')


String::contains = (it) ->
  @indexOf(it) != -1

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
      body: {}

    @response =
      status: ''
      schema: null
      headers: null
      body: null

  url: () ->
    path = @request.path

    for key, value of @request.params
      path = path.replace "{#{key}}", value

    return @request.server + path

  run: (callback) ->
    assertResponse = @assertResponse

    options = _.pick @request, 'headers', 'method'
    options['url'] = @url()
    options['body'] = JSON.stringify @request.body
    options['qs'] = @request.query

    async.waterfall [
      (callback) ->
        request options, (error, response, body) ->
          callback null, error, response, body
      ,
      (error, response, body, callback) ->
        assertResponse(error, response, body)
        callback()
    ], callback

  assertResponse: (error, response, body) =>
    assert.isNull error
    assert.isNotNull response, 'Response'

    # Status code
    assert.equal response.statusCode, @response.status, """
      Got unexpected response code:
      #{body}
      Error
    """

    # Body
    if @response.schema
      schema = @response.schema
      validateJson = _.partial JSON.parse, body
      body = '[empty]' if body is ''
      assert.doesNotThrow validateJson, JSON.SyntaxError, """
        Invalid JSON:
        #{body}
        Error
      """

      json = validateJson()
      assert.jsonSchema json, schema, """
        Got unexpected response body:
        #{JSON.stringify(json, null, 4)}
        Error
      """

      # Update @response
      @response.body = json

module.exports = Test
