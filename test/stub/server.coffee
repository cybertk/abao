###*
# @file Server stub
###

require 'coffee-script/register'

express = require 'express'

app = express()
app.set 'port', process.env.PORT || 3333

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

