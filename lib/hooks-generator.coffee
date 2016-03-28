fs = require 'fs'

generateHooks = (names, fileName, callback) ->

  return unless names
  # TODO make it with templates files
  fileContent = "var hooks = require('hooks');\n\n"

  for key, name of names
    fileContent = fileContent + "hooks.before('#{name}', function(test, done) {\n\tdone();\n});\n"
    fileContent = fileContent + "hooks.after('#{name}', function(test, done) {\n\tdone();\n});\n"
    fileContent = fileContent + "\n"

  fs.writeFile fileName, fileContent, (err) ->
    if err
      console.log err
    else
      console.log "Hooks file #{fileName} generated"
    callback

module.exports = generateHooks
