###*
# @file Generates hooks stub file
###

fs = require 'fs'
Mustache = require 'mustache'

generateHooks = (names, ramlFile, templateFile, callback) ->
  if !names
    callback new Error 'no names found for which to generate hooks'

  if !templateFile
    callback new Error 'missing template file'

  try
    template = fs.readFileSync templateFile, 'utf8'
    datetime = new Date().toISOString().replace('T', ' ').substr(0, 19)
    view =
      ramlFile: ramlFile
      timestamp: datetime
      hooks:
        { 'name': name } for name in names
    view.hooks[0].comment = true

    content = Mustache.render template, view
    console.log content
  catch error
    console.error 'failed to generate skeleton hooks'
    callback error

  callback

module.exports = generateHooks

