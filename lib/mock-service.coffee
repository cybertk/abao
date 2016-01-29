ramlMocker = require 'raml-mocker'
_ = require 'underscore'
express = require 'express'
Faker = require 'faker/locale/zh_CN'
http = require 'http'

generateMockOptions = (options, obj) ->
  options = {} if not options
  if _.isObject(obj)
    for key, value of obj
      if _.isFunction(value)
        options[key] = value
      else
        generateMockOptions(options, value)
  options

generateIntegerFormat = (formats, byteWidth) ->

  formats["uint#{byteWidth}"] = ->
    Math.random() * Math.pow(2, byteWidth)

  formats["int#{byteWidth}"] = ->
    minus = if Math.random() > 0.5 then -1 else 1
    minus * Math.random() * Math.pow(2, byteWidth)

extendFakerFormat = (formats) ->
  customizedFormats =
    date: () ->
      '2015-01-01'

    'date-time': () ->
      '2015-01-01T15:05:06+08:00'

    email: (faker, schema) ->
      Faker.internet.email()

    uri: (faker, schema) ->
      Faker.internet.url()

  generateIntegerFormat(formats, 32)
  generateIntegerFormat(formats, 64)
  _.extend formats, customizedFormats

class MockService

  constructor: (config) ->

    config.files = [config.files] if !_.isArray(config.files)
    if _.isString(config.hostinfo)
      [hostinfo, protocol, doamin, port] = config.hostinfo.match(/(http:\/\/)?(.+)\:(\d+)/)
    else
      doamin = null
      port = null
    @domain = doamin or 'wm.com'
    @port = port or 3000
    # Use faker format as default value
    formats = generateMockOptions({}, Faker)
    formats = extendFakerFormat(formats)
    @options =
      files: config.files
      formats: formats


  start: ->
    app = express()
    files = @options.files
    domain = @domain
    port = @port

    app.all '*', (req, res, next) ->
      res.set 'Access-Control-Allow-Origin', "http://#{domain}"
      res.set 'Access-Control-Allow-Headers', 'Content-Type, Content-Length, Authorization, Accept, X-Requested-With'
      res.set 'Access-Control-Allow-Methods', 'PUT, POST, GET, DELETE, OPTIONS'
      res.set 'Access-Control-Allow-Credentials', 'true'
      res.set 'X-Powered-By', 'abao mock service'
      res.set 'Content-Type', 'application/json;charset=utf-8'
      # Handle preflight request
      if req.method is 'OPTIONS'
        res.send 200
      else
        next()

    ramlMocker.generate @options, (requestsToMock) ->
      _.each requestsToMock, (reqToMock) ->
        app[reqToMock.method] reqToMock.uri, (req, res) ->
          code = 200
          example = null
          mock = null
          code = reqToMock.defaultCode  if reqToMock.defaultCode
          example = reqToMock.example()  if _.isFunction(reqToMock.example)
          mock = reqToMock.mock()  if _.isFunction(reqToMock.mock)
          res.status(code).send mock

      http.createServer(app).listen port, ->
        files = files.join(',')
        console.log "Starting up mock service, serving #{files} on: http://#{domain}:#{port}"

module.exports = MockService
