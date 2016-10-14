async = require 'async'
_ = require 'underscore'
csonschema = require 'csonschema'

selectSchemes = (names, schemes) ->
  return _.pick(schemes, names)

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

  parent ?= {
    path: "",
    params: {}
  }

  top_securedBy = raml.securedBy ? parent.securedBy

  if not parent.security_schemes?
    parent.security_schemes = {}
    for scheme_map in raml.securitySchemes ? []
      for scheme_name, scheme of scheme_map
        parent.security_schemes[scheme_name] ?= []
        parent.security_schemes[scheme_name].push(scheme)

  # Iterate endpoint
  async.each raml.resources, (resource, callback) ->
    path = resource.relativeUri
    params = {}
    query = {}

    resource_securedBy = resource.securedBy ? top_securedBy

    # Apply parent properties
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
      headers = parseHeaders(api.headers)
      method_securedBy = api.securedBy ? resource_securedBy

      # Setup query
      if api.queryParameters
        for qkey, qvalue of api.queryParameters
          if (!!qvalue.required)
            query[qkey] = qvalue.example

      buildTest = (status, res, security) ->
        testName = "#{method} #{path} -> #{status}"
        if security?
          testName += " (#{security})"
        if testName in hooks.skippedTests
          return null

        # Append new test to tests
        test = testFactory.create(testName, hooks.contentTests[testName])

        # Update test.request
        test.request.path = path
        test.request.method = method
        test.request.headers = headers

        # select compatible content-type in request body (to support vendor tree types, i.e. application/vnd.api+json)
        contentType = (type for type of api.body when type.match(/^application\/(.*\+)?json/i))?[0]
        if contentType
          test.request.headers['Content-Type'] = contentType
          try
            test.request.body = JSON.parse api.body[contentType]?.example
          catch
            console.warn "cannot parse JSON example request body for #{test.name}"
        test.request.params = params
        test.request.query = query

        # Update test.response
        test.response.status = status
        test.response.schema = null

        if res?.body
          # expect content-type of response body to be identical to request body
          if contentType && res.body[contentType]?.schema
            test.response.schema = parseSchema res.body[contentType].schema
          # otherwise filter in responses section for compatible content-types
          # (vendor tree, i.e. application/vnd.api+json)
          else
            contentType = (type for type of res.body when type.match(/^application\/(.*\+)?json/i))?[0]
            if res.body[contentType]?.schema
              test.response.schema = parseSchema res.body[contentType].schema
        return test

      # Iterate response status
      for status, res of api.responses
        t = buildTest(status, res)
        if t?
          tests.push t

      for scheme, lst of selectSchemes(method_securedBy, parent.security_schemes)
        for l in lst
          for status, res of l.describedBy?.responses ? {}
            t = buildTest(status, res, scheme)
            if t?
              tests.push t

      callback()
    , (err) ->
      return callback(err) if err

      # Recursive
      new_parent = {
        path, params,
        securedBy: resource_securedBy,
        security_schemes: parent.security_schemes
      }
      addTests resource, tests, hooks, new_parent, callback, testFactory
  , callback


module.exports = addTests

