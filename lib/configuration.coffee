###*
# @file Stores command line arguments in configuration object
###

_ = require 'lodash'
path = require 'path'

abaoOptions = require './options-abao'
mochaOptions = require './options-mocha'
allOptions = _.assign {}, abaoOptions, mochaOptions


applyConfiguration = (config) ->
  'use strict'

  coerceToArray = (value) ->
    if typeof value is 'string'
      value = [value]
    else if !value?
      value = []
    else if value instanceof Array
      value
    else value
    return value

  coerceToDict = (value) ->
    array = coerceToArray value
    dict = {}

    if array.length > 0
      for item in array
        [key, value] = item.split(':')
        dict[key] = value

    return dict

  configuration =
    ramlPath: null
    options:
      server: null
      schemas: null
      'generate-hooks': false
      template: null
      timeout: 2000
      reporter: null
      header: null
      names: false
      hookfiles: null
      grep: ''
      invert: false
      'hooks-only': false
      sorted: false

  # Normalize options and config
  for own key, value of config
    configuration[key] = value

  # Customize
  if !configuration.options.template
    defaultTemplate = path.join 'templates', 'hookfile.js'
    configuration.options.template = defaultTemplate
  configuration.options.header = coerceToDict(configuration.options.header)

  # TODO(quanlong): OAuth2 Bearer Token
  if configuration.options.oauth2Token?
    configuration.options.headers['Authorization'] = "Bearer #{configuration.options.oauth2Token}"

  return configuration

# Create configuration settings from CLI arguments applied against options
# @param {Object} parsedArgs - yargs .argv() output
# @returns {Object} configuration object
asConfiguration = (parsedArgs) ->
  ## TODO(plroebuck): Do all configuration in one place...
  aliases = Object.keys(allOptions).map (key) -> allOptions[key].alias
              .filter (val) -> val != undefined
  alreadyHandled = [
    'reporters',
    'help',
    'version'
  ]

  configuration =
    ramlPath: parsedArgs._[0],
    options: _.omit parsedArgs, ['_', '$0', aliases..., alreadyHandled...]

  mochaOptionNames = Object.keys mochaOptions
  optionsToReparent = _.pick configuration.options, mochaOptionNames
  configuration.options = _.omit configuration.options, mochaOptionNames
  configuration.options.mocha = optionsToReparent

  return applyConfiguration configuration


module.exports = asConfiguration

