chai = require 'chai'
request = require 'request'
_ = require 'underscore'
async = require 'async'
tv4 = require 'tv4'
$RefParser = require 'json-schema-ref-parser'
fs = require 'fs'
glob = require 'glob'

assert = chai.assert


String::contains = (it) ->
  @indexOf(it) != -1


class TestFactory
  constructor: (schemaLocation, @loadFileRefs) ->
    @loadFileRefs ?= false
    if schemaLocation

      files = glob.sync schemaLocation
      console.error 'Found JSON ref schemas: ' + files
      console.error ''

      tv4.banUnknown = true

      for file in files
        tv4.addSchema(JSON.parse(fs.readFileSync(file, 'utf8')))

  create: (name, contentTest) ->
    loadFileRefs = @loadFileRefs
    return new Test(name, contentTest, loadFileRefs)


class Test
  constructor: (@name, @contentTest, @loadFileRefs) ->
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
      expanded_schema: null
      headers: null
      body: null

    @contentTest ?= (response, body, done) ->
      done()

  url: () ->
    path = @request.server + @request.path

    for key, value of @request.params
      path = path.replace "{#{key}}", value
    return path

  run: (callback) ->
    expandSchema = @expandSchema
    saveExpandedSchema = @saveExpandedSchema
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
        expandSchema callback
      ,
      (expanded_schema, callback) ->
        saveExpandedSchema expanded_schema, callback
      ,
      (callback) ->
        request options, (error, response, body) ->
          callback null, error, response, body
      ,
      (error, response, body, callback) ->
        assertResponse(error, response, body)
        contentTest(response, body, callback)
    ], callback

  expandSchema: (callback) =>
    # If loadFileRefs is falsy, the user does not want
    # to expand local file refs, so we disable ref expansion
    # We always disable URL ref parsing, since tv4 already does that
    if @response.schema && @loadFileRefs
      schema = @response.schema
      options = {
        resolve: {
          http: false
        }
      }
      $RefParser.dereference schema, options, callback
    else
      callback null, null

  saveExpandedSchema: (expanded_schema, callback) =>
    if expanded_schema != null
      @response.expanded_schema = expanded_schema
    else
      @response.expanded_schema = @response.schema
    callback null

  assertResponse: (error, response, body) =>
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
    if @response.schema
      assert.isNotNull body, """
        Got null response body.  Schema:  #{JSON.stringify(@response.schema, null, 4)}
      """
      # Use expanded schema here
      schema = @response.expanded_schema
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
      @response.body = json

module.exports = TestFactory
