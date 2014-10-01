fs = require 'fs'

Mocha = require 'mocha'
generateTests = require './generate-tests'

options = require './options'


class Abao
  constructor: (config) ->
    @configuration = config

  run: (callback) ->
    config = @configuration

    fs.readFile config.ramlPath, 'utf8', (loadingError, data) ->
      return callback(loadingError, {}) if loadingError

      mocha = new Mocha config.options
      generateTests data, mocha, config.server, ->
        mocha.run ->
          callback(null, mocha.reporter.stats)


module.exports = Abao
module.exports.options = options
