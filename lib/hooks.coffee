###*
# @file Hooks class
###

async = require 'async'
_ = require 'lodash'


class Hooks
  constructor: () ->
    'use strict'
    @beforeHooks = {}
    @afterHooks = {}
    @beforeAllHooks = []
    @afterAllHooks = []
    @beforeEachHooks = []
    @afterEachHooks = []
    @contentTests = {}
    @skippedTests = []

  before: (name, hook) =>
    'use strict'
    @addHook @beforeHooks, name, hook

  after: (name, hook) =>
    'use strict'
    @addHook @afterHooks, name, hook

  beforeAll: (hook) =>
    'use strict'
    @beforeAllHooks.push hook

  afterAll: (hook) =>
    'use strict'
    @afterAllHooks.push hook

  beforeEach: (hook) =>
    'use strict'
    @beforeEachHooks.push hook

  afterEach: (hook) =>
    'use strict'
    @afterEachHooks.push hook

  addHook: (hooks, name, hook) ->
    'use strict'
    if hooks[name]
      hooks[name].push hook
    else
      hooks[name] = [hook]

  test: (name, hook) =>
    'use strict'
    if @contentTests[name]?
      throw new Error "cannot have more than one test with the name: #{name}"
    @contentTests[name] = hook

  runBeforeAll: (callback) =>
    'use strict'
    async.series @beforeAllHooks, (err, results) ->
      callback(err)

  runAfterAll: (callback) =>
    'use strict'
    async.series @afterAllHooks, (err, results) ->
      callback(err)

  runBefore: (test, callback) =>
    'use strict'
    return callback() unless (@beforeHooks[test.name] or @beforeEachHooks)

    hooks = @beforeEachHooks.concat(@beforeHooks[test.name] ? [])
    async.eachSeries hooks, (hook, callback) ->
      hook test, callback
    , callback

  runAfter: (test, callback) =>
    'use strict'
    return callback() unless (@afterHooks[test.name] or @afterEachHooks)

    hooks = (@afterHooks[test.name] ? []).concat(@afterEachHooks)
    async.eachSeries hooks, (hook, callback) ->
      hook test, callback
    , callback

  skip: (name) =>
    'use strict'
    @skippedTests.push name

  hasName: (name) =>
    'use strict'
    _.has(@beforeHooks, name) || _.has(@afterHooks, name)

  skipped: (name) =>
    'use strict'
    @skippedTests.indexOf(name) != -1



module.exports = new Hooks()

