{after} = require 'hooks'

after 'GET /machines -> 200', (test, done) ->
  console.error 'after-hook-GET-machines'
  done()
