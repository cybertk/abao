path = require 'path'

require 'coffee-script/register'
proxyquire = require('proxyquire').noCallThru()
glob = require 'glob'


addHooks = (hooks, pattern) ->

  return unless pattern

  files = glob.sync pattern

  console.error 'Found Hookfiles: ' + files

  try
    for file in files
      proxyquire path.resolve(process.cwd(), file), {
        'hooks': hooks
      }
  catch error
    console.error 'Skipping hook loading...'
    console.error 'Error reading hook files (' + files + ')'
    console.error 'This probably means one or more of your hookfiles is invalid.'
    console.error 'Message: ' + error.message if error.message?
    console.error 'Stack: ' + error.stack if error.stack?
    return


module.exports = addHooks

