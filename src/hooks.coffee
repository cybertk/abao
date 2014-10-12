async = require 'async'
_ = require 'underscore'

class Hooks
  constructor: () ->
    @beforeHooks = {}
    @afterHooks = {}
    @beforeAllHooks = []
    @afterAllHooks = []

  before: (name, hook) =>
    @addHook(@beforeHooks, name, hook)

  after: (name, hook) =>
    @addHook(@afterHooks, name, hook)

  beforeAll: (hook) =>
    @beforeAllHooks.push hook

  afterAll: (hook) =>
    @afterAllHooks.push hook

  addHook: (hooks, name, hook) =>
    if hooks[name]
      hooks[name].push hook
    else
      hooks[name] = [hook]

  runBeforeAll: (callback) =>
    async.series @beforeAllHooks, callback

  runAfterAll: (callback) =>
    async.series @afterAllHooks, callback

  runBefore: (test, callback) =>
    return callback() unless @beforeHooks[test.name]

    async.eachSeries @beforeHooks[test.name], (hook, callback) ->
      hook test, callback
    , callback

  runAfter: (test, callback) =>
    return callback() unless @afterHooks[test.name]

    async.eachSeries @afterHooks[test.name], (hook, callback) ->
      hook test, callback
    , callback

  hasName: (name) =>
    _.has(@beforeHooks, name) || _.has(@afterHooks, name)

module.exports = new Hooks()
