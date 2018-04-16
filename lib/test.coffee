###*
# @file TestFactory/Test classes
###

async = require 'async'
chai = require 'chai'
fs = require 'fs'
glob = require 'glob'
_ = require 'lodash'
request = require 'request'
tv4 = require 'tv4'

assert = chai.assert


class TestFactory
  constructor: (pattern) ->
    'use strict'
    if pattern

      files = glob.sync pattern
      console.log '\tJSON ref schemas: ' + files.join(', ')

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

    @contentTest ?= (response, body, callback) ->
      return callback null

  url: () ->
    'use strict'
    path = @request.server + @request.path

    for key, value of @request.params
      path = path.replace "{#{key}}", value
    return path

  run: (done) ->
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

    makeHTTPRequest = (callback) ->
      requestCB = (error, response, body) ->
        if error
          maybeReplaceMessage = (error) ->
            error.message = switch
              when error?.code == 'ETIMEDOUT' and error?.connect
                'timed out attempting to establish connection'
              when error?.code == 'ETIMEDOUT'
                'timed out awaiting server response'
              when error?.code == 'ESOCKETTIMEDOUT'
                'timed out when server stopped sending response data'
              when error?.code == 'ECONNRESET'
                'connection reset by server'
              else
                error.message
            return error

          return callback maybeReplaceMessage error
        return callback null, response, body
      request options, requestCB

    async.waterfall [
      makeHTTPRequest,
      (response, body, callback) ->
        assertResponse response, body
        contentTest response, body, callback
    ], done

  # TODO(plroebuck): add callback parameter and use it...
  assertResponse: (response, body) =>
    'use strict'
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

      # Validate object against JSON schema
      checkRecursive = false
      banUnknown = false
      result = tv4.validateResult json, schema, checkRecursive, banUnknown

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

