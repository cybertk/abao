async = require 'async'
_ = require 'underscore'
csonschema = require 'csonschema'
glob = require 'glob'
fs = require 'fs'

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

parseFolderPath = (path, method, status) ->
  method = method.toLowerCase()
  path = path.replace(/\{.+\}$/, 'detail')
  [path.replace(/\/\{.+?\}/g, ''), method.toLowerCase(), status].join('/')


addCases = (tests, api, path, method, testFactory, callback, baseCaseFolder) ->
  responses = []
  # Generate array for asyn each function
  for status, res of api.responses
    responses.push
      status: status
      res: res

  async.each responses, (obj, callback) ->
    caseFolder = baseCaseFolder + parseFolderPath(path, method, obj.status)
    glob("#{caseFolder}/*.json", (err, files) ->

      if files.length and not err
        async.each files, (file, callback) ->
          json = fs.readFileSync(file, 'utf-8')
          definition = JSON.parse json

          # Append new test to tests
          test = testFactory.create()
          tests.push test
          test.name = "#{method} #{path} -> #{obj.status}"

          test.request.path = path
          test.request.method = method
          # Only use the definition for params in case the lack of example in RAML
          test.request.params = definition.params or {}
          test.request.query = definition.query or {}
          test.request.body = definition.body or {}
          test.request.headers = definition.headers or {}
          _.extend(test.request.headers, parseHeaders(api.headers))
          # Use json as default content type
          if not test.request.headers['Content-Type']
            test.request.headers['Content-Type'] = 'application/json'

          test.response = definition.response

          # Update test.response
          test.response.status = obj.status
          test.response.schema = null
          if (obj.res?.body?['application/json']?.schema)
            test.response.schema = parseSchema obj.res.body['application/json'].schema

          callback()
        , (err) ->
          return callback(err) if err

      else
        callback()
    )
  , (err) ->
    return callback(err) if err

addTests = (raml, tests, basePath, callback, testFactory, baseCaseFolder) ->

  # Handle 3th optional param
  if _.isFunction(basePath)
    baseCaseFolder = testFactory
    testFactory = callback
    callback = basePath
    basePath = ''

  # TODO: Make it a configuration
  baseCaseFolder = 'test' if not baseCaseFolder

  return callback() unless raml.resources

  # Iterate endpoint
  async.each raml.resources, (resource, callback) ->
    path = resource.relativeUri

    # Apply parent path
    path = basePath + path if basePath

    # In case of issue #8, resource does not define methods
    resource.methods ?= []

    # Iterate response method
    async.each resource.methods, (api, callback) ->
      method = api.method.toUpperCase()
      addCases tests, api, path, method, testFactory, callback, baseCaseFolder
    , (err) ->
      return callback(err) if err

    # Add all tests for a resource path
    addTests resource, tests, path, callback, testFactory, baseCaseFolder
  , callback


module.exports = addTests
