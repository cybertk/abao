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
    console.log('callback addtests' +'dir resoure :/n')
    # console.log(JSON.stringify(resource, null, 2))
    # console.log(JSON.stringify(resource.resources[0].methods, null, 2))

    # Apply parent properties
    if parent
      path = parent.path + path
      params = _.clone parent.params
      queryparent = _.clone parent.query
      console.log('parent query is :')
      console.log(JSON.stringify(queryparent, null, 2))


    # Setup param
    if resource.uriParameters
      console.dir('your uriParameters' + resource.uriParameters)
      for key, param of resource.uriParameters
        params[key] = param.example


    # In case of issue #8, resource does not define methods
    resource.methods ?= []

    # Iterate response method
    async.each resource.methods, (api, callback) ->
      method = api.method.toUpperCase()
      # Setup query
      if api.queryParameters

        console.log('your methods.queryParameters is ' + api.queryParameters )
        console.log(JSON.stringify(api.queryParameters, null, 2))

        for qkey, qvalue of api.queryParameters
          query[qkey] = qvalue.example
          # console.log('qkey is :'  + 'qvalue is : qvalue.example' )
        console.log('the queryParameters is:' + query )
        console.log(JSON.stringify(query, null, 2))



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
        test.request.params = params
        console.log('this test queryParameters is:' + query )
        console.log(JSON.stringify(query, null, 2))
        console.log(test.request)
        test.request.query = query
        console.log('this test queryParameters is:' + query )
        console.log(JSON.stringify(query, null, 2))

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

