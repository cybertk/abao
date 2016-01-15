async = require 'async'
glob = require 'glob'
fs = require 'fs'
_ = require 'underscore'

parseFolderPath = (path, method) ->
  path = path.replace(/\{.+\}$/, 'detail')
  [path.replace(/\/\{.+?\}/g, ''), method.toLowerCase()].join('/')


# addCases(raml, tests, [parent], callback, config)
addCases = (raml, tests, parent, callback, testFactory) ->
  # TODO: Make it a configuration
  baseTestFolder = 'test'

  # Handle 3th optional param
  if _.isFunction(parent)
    testFactory = callback
    callback = parent
    parent = null

  return callback() unless raml.resources

  # Iterate endpoint
  async.each raml.resources, (resource, callback) ->
    path = resource.relativeUri
    params = {}

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
      caseFolder = baseTestFolder + parseFolderPath(path, api.method)
      glob("#{caseFolder}/*.json", (err, files) ->

        [].forEach((file) ->
          json = fs.readFileSync(file, 'utf-8')
          definition = JSON.parse json

          # Append new test to tests
          test = testFactory.create()
          tests.push test

          test.name = "Case: #{method} #{path} -> #{definition.response.status}"
          test.isCase = true

          test.request.path = path
          test.request.method = method
          test.request.params = definition.params or {}
          test.request.query = definition.query or {}
          test.request.body = definition.body or {}
          test.request.headers = definition.headers or {}
          # Use json as default content type
          if not test.request.headers['Content-Type']
            test.request.headers = [
              'Content-Type': 'application/json'
            ]

          test.response = definition.response
          console.log test
        )
      )

      callback()
    , (err) ->
      return callback(err) if err

      # Add all tests for a resource path
      addCases resource, tests, {path, params}, callback, testFactory
  , callback


module.exports = addCases
