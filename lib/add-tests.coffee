async = require 'async'
_ = require 'underscore'
csonschema = require 'csonschema'


parseSchema = (source) ->
  if source.contains('$schema')
    #jsonschema
    # @response.schema = JSON.parse @response.schema
    JSON.parse source
  else
    csonschema.parse source
    # @response.schema = csonschema.parse @response.schema

parseHeaders = (raml) ->
  return {} unless raml

  headers = {}
  for key, v of raml
    headers[key] = v.example

  headers

# addTests(raml, tests, [parent], callback, config)
addTests = (raml, tests, hooks, parent, callback, testFactory) ->

  # Handle 4th optional param
  if _.isFunction(parent)
    testFactory = callback
    callback = parent
    parent = null

  return callback() unless raml.resources

  # Iterate endpoint
  async.each raml.resources, (resource, callback) ->
    path = resource.relativeUri
    params = {}
    query = {}

    # Apply parent properties
    if parent
      path = parent.path + path
      params = _.clone parent.params

    # Setup param
    if resource.uriParameters
      for key, param of resource.uriParameters
        params[key] = param.example


    # In case of issue #8, resource does not define methods
    resource.methods ?= []

    # Iterate response method
    async.each resource.methods, (api, callback) ->
      method = api.method.toUpperCase()

      # Setup query
      if api.queryParameters
        for qkey, qvalue of api.queryParameters
          query[qkey] = qvalue.example


      # Iterate response status
      for status, res of api.responses

        testName = "#{method} #{path} -> #{status}"

        # Append new test to tests
        test = testFactory.create(testName, hooks.contentTests[testName])
        tests.push test

        # Update test.request
        test.request.path = path
        test.request.method = method
        test.request.headers = parseHeaders(api.headers)

        # select compatible content-type in request body (to support vendor tree types, i.e. application/vnd.api+json)
        contentType = (type for type of api.body when type.match(/^application\/(.*\+)?json/i))?[0]
        if contentType
          test.request.headers['Content-Type'] = contentType
          try
            test.request.body = JSON.parse api.body[contentType]?.example
          catch
            console.warn "invalid request example of #{test.name}"
        # console.dir('your params is ' + params)
        test.request.params = params
        test.request.query = query

        # Update test.response
        test.response.status = status
        test.response.schema = null
        if (res?.body?['application/json']?.schema)
          test.response.schema = parseSchema res.body['application/json'].schema

      callback()
    , (err) ->
      return callback(err) if err

      # Recursive
      addTests resource, tests, hooks, {path, params}, callback, testFactory
  , callback


module.exports = addTests

