chai = require 'chai'
request = require 'request'
_ = require 'underscore'
async = require 'async'
tv4 = require 'tv4'
fs = require 'fs'
glob = require 'glob'

assert = chai.assert

String::contains = (it) ->
  @indexOf(it) != -1

class TestFactory
  constructor: (schemaLocation) ->
    if schemaLocation

      files = glob.sync schemaLocation
      console.error 'Found JSON ref schemas: ' + files
      console.error ''

      tv4.banUnknown = true;

      for file in files
        tv4.addSchema(JSON.parse(fs.readFileSync(file, 'utf8')))

  create: () ->
    return new Test()

class Test
  constructor: () ->
    @name = ''
    @skip = false

    @request =
      server: ''
      path: ''
      version: ''
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
    versionPath = if @request.version then '/' + @request.version else ''
    path = @request.server + versionPath + @request.path
    for key, value of @request.params
      path = path.replace "{#{key}}", value
    return path

  run: (callback) ->
    assertResponse = @assertResponse

    options = _.pick @request, 'headers', 'method'
    options['url'] = @url()
    options['body'] = JSON.stringify @request.body
    options['qs'] = @request.query

    async.waterfall [
      (callback) ->
        # Send request
        request options, (error, response, body) ->
          callback null, error, response, body, options
      ,
      (error, response, body, options, callback) ->
        # Assert response
        assertResponse error, response, body, options
        callback()
    ], callback

  assertResponse: (error, response, body, options) =>
    # TODO: Add more assertion and show more detailed information
    assert.isNull error
    assert.isNotNull response, 'Response'

    # Status code
    assert.equal response.statusCode, @response.status, """
      Response code does not match definition in RAML file
      * Request JSON options:
      #{JSON.stringify(options, null, 2)}
      * Response raw data:
      #{body}
      * Assertion error
    """

    if body is ''
      console.warn 'The response body is empty'
    else
      # Parse JSON payload
      validateJson = _.partial JSON.parse, body

      assert.doesNotThrow validateJson, JSON.SyntaxError, """
        Server response data is not JSON format
        * Request JSON options:
        #{JSON.stringify(options, null, 2)}
        * Response raw data:
        #{body}
        * Assertion error
      """

      json = validateJson()

      # Validate based on case sample
      if @response.body
        expectedBody = @response.body
        assert.deepEqual json, expectedBody

      # Validate based on schema
      if @response.schema
        schema = @response.schema

        result = tv4.validateResult json, schema, true, true
        assert.ok result.valid, """
          Server response data does not match RAML schema definition
          * Error message: #{result?.error?.message}
          * Request JSON options:
          #{JSON.stringify(options, null, 2)}
          * Response JSON data:
          #{JSON.stringify(json, null, 2)}
          * Schema definition:
          #{JSON.stringify(schema, null, 2)}
          * Detailed validation result:
          #{JSON.stringify(result, null, 2)}
          * Assertion error
        """

      # Update @response
      @response.body = json

module.exports = TestFactory
