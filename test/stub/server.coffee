###*
# @file Express server stub
#
# Start:
# $ ../../node_modules/coffee-script/bin/coffee server.coffee
###

require 'coffee-script/register'

express = require 'express'

app = express()
app.set 'port', process.env.PORT || 3333

app.options '/machines', (req, res) ->
  'use strict'
  allow = ['OPTIONS', 'HEAD', 'GET']
  res.setHeader 'Allow', allow.join ', '
  res.setHeader 'Cache-Control', 'no-cache, no-store, must-revalidate'
  res.status(204).end()

app.get '/machines', (req, res) ->
  'use strict'
  machine =
    type: 'bulldozer'
    name: 'willy'
  res.status(200).json [machine]

app.use (err, req, res, next) ->
  'use strict'
  res.status(err.status || 500)
    .json({
      message: err.message,
      stack: err.stack
    })
  return

server = app.listen app.get('port'), () ->
  'use strict'
  console.log 'server listening on port', server.address().port

