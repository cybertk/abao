{after} = require 'hooks'

after 'GET /machines -> 200', (test, done) ->
  'use strict'
  console.error 'after-hook-GET-machines'
  done()

