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
  if /\}$/.test(path)
    path = path.slice(0, path.lastIndexOf('{')) + 'detail'
  [path.replace(/\/\{.+?\}/g, ''), method.toLowerCase(), status].join('/')

addTest = (tests, path, method, testFactory, status, definition, res, headers) ->
  test = testFactory.create()
  tests.push test
  name = if definition?.name then definition?.name else ''
  prefix = ''
  prefix = 'Depended case:' if definition?.depended

  test.name = "#{prefix} #{method} #{path} -> #{status} : #{name}"

  test.request.path = path
  test.request.method = method.toUpperCase()

  # Only use the definition for params in case the lack of example in RAML
  test.loadtest = definition?.loadtest

  test.request.params = definition?.params or {}
  test.request.query = definition?.query or {}
  test.request.body = definition?.body or {}
  test.request.headers = definition?.headers or {}
  _.extend(test.request.headers, parseHeaders(headers)) if headers
  # Use json as default content type
  if not test.request.headers['Content-Type']
    test.request.headers['Content-Type'] = 'application/json'

  test.response = definition?.response or {}

  # Update test.response
  test.response.status = status
  test.response.schema = null
  if (res?.body?['application/json']?.schema)
    test.response.schema = parseSchema res.body['application/json'].schema

  test.destroy = definition?.destroy
  test.depended = definition?.depended

  test

addAuthCase = (tests, path, method, testFactory) ->
  test = addTest(tests, path, method, testFactory, '401')
  test.isAuthCheck = true

###
addPaginationCase = (tests, path, method, testFactory) ->
  # Resource not available case
  test = addTest(tests, path, method, testFactory, '204')
  test.name = 'Big page number: ' + test.name
  test.request.query =
    page: 1000000
###

addCases = (tests, api, path, method, testFactory, callback, baseCaseFolder) ->
  responses = []
  # Generate array for asyn each function
  for status, res of api.responses
    responses.push
      status: status
      res: res

  # Add auth validation
  addAuthCase tests, path, method, testFactory

  # Add pagination validation
  ###
  if method is 'GET' and path.match(/\/.+s$/) and path.indexOf('{') is -1
    addPaginationCase tests, path, method, testFactory
  ###

  async.each responses, (obj, callback) ->
    caseFolder = baseCaseFolder + parseFolderPath(path, method, obj.status)
    glob("#{caseFolder}/*.json", (err, files) ->

      if files.length and not err
        async.each files, (file, callback) ->
          json = fs.readFileSync(file, 'utf-8')
          # Support put empty file
          json = '{}' if not json
          definition = JSON.parse json
          definition.name = file.slice(0, file.lastIndexOf('.'))

          destroy = []
          # Add depended test cases
          if definition.depends
            if typeof definition.depends is 'object' and definition.depends.constructor isnt Array
              definition.depends = [definition.depends]
            for depend in definition.depends
              caseFolder = baseCaseFolder + parseFolderPath(depend.path, depend.method, depend.status)
              dependFile = "#{caseFolder}/#{depend.case}"
              dependDef = JSON.parse(fs.readFileSync(dependFile, 'utf8'))
              dependDef.name = dependFile.slice(0, dependFile.lastIndexOf('.'))
              # Mark the depended test case
              dependDef.depended = true
              # Delete the destory handling for the dependencies
              if dependDef.destroy
                destroy = destroy.concat(dependDef.destroy)
                dependDef.destroy = null
              dependDef.loadtest = null
              addTest(tests, depend.path, depend.method, testFactory, depend.status, dependDef)

          # Move the destory handling to the next case
          definition.destroy = [] if not definition.destroy
          definition.destroy = destroy.concat definition.destroy
          # Append new test to tests
          addTest(tests, path, method, testFactory, obj.status, definition, obj.res, api.headers)

          callback()
        , (err) ->
          return callback(err) if err

      else
        callback()
    )
  , (err) ->
    return callback(err) if err

addTests = (raml, tests, callback, testFactory, baseCaseFolder, basePath) ->
  basePath = '' if not basePath
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
    addTests resource, tests, callback, testFactory, baseCaseFolder, path
  , callback


module.exports = addTests
