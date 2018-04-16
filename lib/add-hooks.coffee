###*
# @file Load user hooks
###

require 'coffee-script/register'
glob = require 'glob'
path = require 'path'
proxyquire = require('proxyquire').noCallThru()


addHooks = (hooks, pattern, callback) ->
  'use strict'
  if pattern
    files = glob.sync pattern

    if files.length == 0
      nomatch = new Error "no hook files found matching pattern '#{pattern}'"
      return callback nomatch

    console.info 'processing hook file(s):'
    try
      files.map (file) ->
        absFile = path.resolve process.cwd(), file
        console.info "  #{absFile}"
        proxyquire absFile, {
          'hooks': hooks
        }
      console.log()
    catch error
      console.error 'error loading hooks...'
      return callback error

  return callback null


module.exports = addHooks

