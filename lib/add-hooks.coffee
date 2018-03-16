###*
# @file Load user hooks
###

require 'coffee-script/register'
glob = require 'glob'
path = require 'path'
proxyquire = require('proxyquire').noCallThru()


addHooks = (hooks, pattern) ->

  if pattern
    files = glob.sync pattern

    console.info 'hook file pattern matches: ' + files

    try
      for file in files
        proxyquire path.resolve(process.cwd(), file), {
          'hooks': hooks
        }
    catch error
      console.error 'skipping hook loading...'
      console.group
      console.error 'error resolving absolute paths of hook files (' + files + ')'
      console.error 'the "--hookfiles" pattern is probably invalid.'
      console.error 'message: ' + error.message if error.message?
      console.error 'stack: ' + error.stack if error.stack?
      console.groupEnd
  return


module.exports = addHooks

