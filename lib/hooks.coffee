async = require 'async'


class Hooks
  constructor: () ->
    @beforeHooks = {}
    @afterHooks = {}
    @beforeAllHooks = []
    @afterAllHooks = []
    @beforeEachHooks = []
    @afterEachHooks = []
    @contentTests = {}
    @skippedTests = []

  before: (name, hook) =>
    @addHook(@beforeHooks, name, hook)

  after: (name, hook) =>
    @addHook(@afterHooks, name, hook)

  beforeAll: (hook) =>
    @beforeAllHooks.push hook

  afterAll: (hook) =>
    @afterAllHooks.push hook

  beforeEach: (hook) =>
    @beforeEachHooks.push(hook)

  afterEach: (hook) =>
    @afterEachHooks.push(hook)

  addHook: (hooks, name, hook) ->
    if hooks[name]
      hooks[name].push hook
    else
      hooks[name] = [hook]

  test: (name, hook) =>
    if @contentTests[name]?
      throw new Error("Cannot have more than one test with the name: #{name}")
    @contentTests[name] = hook

  runBeforeAll: (callback) =>
    async.series @beforeAllHooks, (err, results) ->
      callback(err)

  runAfterAll: (callback) =>
    async.series @afterAllHooks, (err, results) ->
      callback(err)

  runBefore: (test, callback) =>
    beforeHook = @getMatchingHook @beforeHooks, test.name
    return callback() unless (beforeHook or @beforeEachHooks)

    hooks = @beforeEachHooks.concat(beforeHook ? [])
    async.eachSeries hooks, (hook, callback) ->
      hook test, callback
    , callback

  runAfter: (test, callback) =>
    afterHook = @getMatchingHook @afterHooks, test.name
    return callback() unless (afterHook or @afterEachHooks)

    hooks = (afterHook ? []).concat(@afterEachHooks)
    async.eachSeries hooks, (hook, callback) ->
      hook test, callback
    , callback

  skip: (name) =>
    @skippedTests.push name

  hasName: (name) =>
    (@getMatchingHook @beforeHooks, name) || (@getMatchingHook @afterHooks, name)

  getMatchingHook: (hooks, name) =>
    for key,value of hooks
      if name.match key
        return value

  skipped: (name) =>
    @skippedTests.indexOf(name) != -1


module.exports = new Hooks()

