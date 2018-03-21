###*
# @file TestFactory/Test classes
###

async = require 'async'
chai = require 'chai'
fs = require 'fs'
glob = require 'glob'
request = require 'request'
tv4 = require 'tv4'
_ = require 'underscore'

assert = chai.assert


String::contains = (it) ->
  'use strict'
  @indexOf(it) != -1


class TestFactory
  constructor: (schemaLocation) ->
    'use strict'
    if schemaLocation

      files = glob.sync schemaLocation
      console.log '\tJSON ref schemas: ' + files.join(', ')

      tv4.banUnknown = true

      for file in files
        tv4.addSchema(JSON.parse(fs.readFileSync(file, 'utf8')))

  create: (name, contentTest) ->
    'use strict'
    return new Test(name, contentTest)



class Test
  constructor: (@name, @contentTest) ->
    'use strict'
    @name ?= ''
    @skip = false

    @request =
      server: ''
      path: ''
      method: 'GET'
      params: {}
      query: {}
      headers: {}
      body: ''

    @response =
      status: ''
      schema: null
      headers: null
      body: null

    @contentTest ?= (response, body, done) ->
      done()

  url: () ->
    'use strict'
    path = @request.server + @request.path

    for key, value of @request.params
      path = path.replace "{#{key}}", value
    return path

  run: (callback) ->
    'use strict'
    assertResponse = @assertResponse
    contentTest = @contentTest

    options = _.pick @request, 'headers', 'method'
    options['url'] = @url()
    if typeof @request.body is 'string'
      options['body'] = @request.body
    else
      options['body'] = JSON.stringify @request.body
    options['qs'] = @request.query

    async.waterfall [
      (callback) ->
        request options, (error, response, body) ->
          callback null, error, response, body
      ,
      (error, response, body, callback) ->
        assertResponse(error, response, body)
        contentTest(response, body, callback)
    ], callback

  assertResponse: (error, response, body) =>
    'use strict'
    assert.isNull error
    assert.isNotNull response, 'Response'

    # Headers
    @response.headers = response.headers

    # Status code
    assert.equal response.statusCode, @response.status, """
      Got unexpected response code:
      #{body}
      Error
    """
    response.status = response.statusCode

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
      result = tv4.validateResult json, schema
      assert.lengthOf result.missing, 0, """
        Missing/unresolved JSON schema $refs (#{result.missing?.join(', ')}) in schema:
        #{JSON.stringify(schema, null, 4)}
        Error
      """
      assert.ok result.valid, """
        Got unexpected response body: #{result.error?.message}
        #{JSON.stringify(json, null, 4)}
        Error
      """

      # Update @response
      @response.body = json


module.exports = TestFactory

