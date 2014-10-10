{after} = require 'hooks'

after "GET /machines -> 200", (test) ->
  console.log "after"
