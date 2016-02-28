express = require 'express'

PORT = '3333'

app = express()

app.get '/machines', (req, res) ->
  res.setHeader 'Content-Type', 'application/json'
  machine =
    type: 'bulldozer'
    name: 'willy'
  response = [machine]
  res.status(200).send response

server = app.listen PORT, () ->
  console.log('server started')

