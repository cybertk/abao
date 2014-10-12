{after} = require 'hooks'

after "GET /machines -> 200", (test, done) ->
  console.log "after"
  done()
