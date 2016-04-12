redis = require 'redis'
_ = require 'underscore'

class RedisClient
    constructor: (url) ->
        @url = url
        @client = redis.createClient @url

    exec: (commands) =>
        client = @client
        @client.multi @formatCommands commands
               .exec (err, replies) ->
                    if err?
                        console.log err
                    client.quit()

    formatCommands: (commands) =>
        if commands? and _.isArray commands
            if commands[..]? and  not _.isArray commands[0]
                commands = [commands]
        else
            commands = []
        commands

module.exports = RedisClient
