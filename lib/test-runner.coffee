Mocha = require 'mocha'
async = require 'async'
_ = require 'underscore'
mongo = require 'mongojs'


class TestRunner
  constructor: (config) ->
    @config = config
    @options = config.options or {}
    @mocha = new Mocha @options
    if @config.db and @config.db.type is 'mongodb'
      @db = mongo(@config.db.dsn)

  transformQuery: (query) =>
    mergedQuery =
      accountId: mongo.ObjectId(@config.accountId)

    for key, value of query
      if (key is '_id' or /Id$/.test(key)) and value.indexOf('!') isnt 0
        query[key] = mongo.ObjectId(value)
      query[key] = value.replace(/^!/, '') if typeof value is 'string'

    _.extend mergedQuery, query

  removeMongoRecord: (model, query) =>
    db = @db
    transformQuery = @transformQuery
    (callback) ->
      query = transformQuery(query)
      db.collection(model).remove(query, (err, result) ->
        if err
          console.error "Fail to clear #{model} data with query:"
          console.error "#{JSON.stringify(mergedQuery, null, 2)}"
          callback err
        else
          console.log "Remove #{model} #{result.n} records"
          callback null
      )

  updateMongoRecord: (model, query, update) =>
    db = @db
    transformQuery = @transformQuery
    (callback) ->
      options =
        multi: true
      query = transformQuery(query)
      db.collection(model).update(query, update, options, (err, result) ->
        if err
          console.error "Fail to update #{model} data with query:"
          console.error "#{JSON.stringify(mergedQuery, null, 2)}"
          callback err
        else
          console.log "Updated #{model} #{result.n} records"
          callback null
      )

  replaceQureyRef: (query, body) =>
    for key, value of query
      if typeof value is 'object'
        if value.constructor is Array
          for item in value
            @replaceQureyRef(item, body)
        else
          @replaceQureyRef(value, body)
      else if typeof value is 'string' and /^\$/.test(value)
        fileds = value.slice(1).split('.')
        value = body
        for field in fileds
          value = value[field]
        query[key] = value
    query

  addTestToMocha: (test, hooks) =>
    mocha = @mocha
    options = @options
    removeMongoRecord = @removeMongoRecord
    updateMongoRecord = @updateMongoRecord
    replaceQureyRef = @replaceQureyRef
    for key, value of test.request.params
      if not value
        # Only show information for matched routes
        if options.grep and test.request.path.match(options.grep)
          testName = "#{test.request.method} #{test.request.path} -> #{test.response.status}"
          tip = 'You need to define it in the example field for uriParameters'
          console.warn "[warn] #{testName} with invalid param { #{key} : #{value} } (Skipped) #{tip}"
        return

    # Generate Test Suite
    suite = Mocha.Suite.create mocha.suite, test.name

    # No Response defined
    if !test.response.status
      suite.addTest new Mocha.Test 'Skip as no response code defined'
      return

    # No Hooks for this test
    if not hooks.hasName(test.name) and options['hooks-only']
      suite.addTest new Mocha.Test 'Skip as no hooks defined'
      return

    # Not GET method for this test
    if test.request.method isnt 'GET' and options['read-only']
      suite.addTest new Mocha.Test 'Skip as is not GET method'
      return

    # Setup hooks
    if hooks
      suite.beforeAll _.bind (done) ->
        @hooks.runBefore @test, done
      , {hooks, test}

      suite.afterAll _.bind (done) ->
        @hooks.runAfter @test, done
      , {hooks, test}

    suite.afterAll _.bind (done) ->
      @test.destroy = [@test.destroy] if @test.destroy and not _.isArray @test.destroy
      body =  @test.response?.body
      tasks = _.map @test.destroy, (item) ->
        item.query = replaceQureyRef(item.query, body)
        if item.update
          updateMongoRecord(item.model, item.query, item.update)
        else
          removeMongoRecord(item.model, item.query)

      if tasks.length
        async.waterfall(tasks, done)
      else
        done()

    , {test}

    # Setup test
    # Vote test name
    title = if test.response.schema then 'Validate response code and body' else 'Validate response code only'
    suite.timeout(10000) if test.loadtest
    suite.addTest new Mocha.Test title, _.bind (done) ->
      # Run actual test case below
      @test.run done
    , {test}

  run: (tests, hooks, callback) ->
    config = @config
    options = @options
    addTestToMocha = @addTestToMocha
    mocha = @mocha

    async.waterfall [
      (callback) ->
        async.each tests, (test, done) ->
          # list tests
          if options.names
            console.log test.name
            return done()

          # Update test.request
          test.request.server = config.server
          test.request.version = config.version
          if not test.isAuthCheck
            _.extend(test.request.query, {access_token: config.accessToken})

          _.extend(test.request.headers, options.header)
          if options.grep and test.request.path.match(options.grep)
            addTestToMocha test, hooks
          else
            addTestToMocha test, hooks
          done()
        , callback
      , # Run mocha
      (callback) ->
        return callback(null, 0) if options.names

        mocha.suite.beforeAll _.bind (done) ->
          @hooks.runBeforeAll done
        , {hooks}
        mocha.suite.afterAll _.bind (done) ->
          @hooks.runAfterAll done
        , {hooks}

        mocha.run (failures) ->
          callback(null, failures)
    ], callback



module.exports = TestRunner
