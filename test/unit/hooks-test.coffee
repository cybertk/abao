require 'coffee-errors'
sinon = require 'sinon'
{assert} = require 'chai'

TestStub = require '../../src/test'

hooks = require '../../src/hooks'

describe 'Hooks', () ->

  describe 'when adding before hook', () ->

    before () ->
      hooks.before 'beforeHook', () ->
        ""
    after () ->
      hooks.beforeHooks = {}

    it 'should add to hook collection', () ->
      assert.property hooks.beforeHooks, 'beforeHook'
      assert.lengthOf hooks.beforeHooks['beforeHook'], 1

  describe 'when adding after hook', () ->

    before () ->
      hooks.after 'afterHook', () ->
        ""
    after () ->
      hooks.afterHooks = {}

    it 'should add to hook collection', () ->
      assert.property hooks.afterHooks, 'afterHook'

  describe 'when adding beforeAll hooks', () ->

    afterEach () ->
      hooks.beforeAllHooks = []

    it 'should invoke registered callbacks', (testDone) ->
      callback = sinon.stub()
      callback.callsArg(0)

      hooks.beforeAll callback
      hooks.beforeAll (done) ->
        assert.ok typeof done is 'function'
        assert.ok callback.called
        done()
      hooks.runBeforeAll (done) ->
        testDone()

  describe 'when adding afterAll hooks', () ->

    afterEach () ->
      hooks.afterAllHooks = []

    it 'should callback if registered', (testDone) ->
      callback = sinon.stub()
      callback.callsArg(0)

      hooks.afterAll callback
      hooks.afterAll (done) ->
        assert.ok(typeof done is 'function')
        assert.ok callback.called
        done()
      hooks.runAfterAll (done) ->
        testDone()

  describe 'when check has name', () ->

    it 'should return true if in before hooks', ->
      hooks.beforeHooks =
        foo: (test, done) ->
          done()

      assert.ok hooks.hasName 'foo'

      hooks.beforeHooks = {}

    it 'should return true if in after hooks', ->
      hooks.afterHooks =
        foo: (test, done) ->
          done()

      assert.ok hooks.hasName 'foo'

      hooks.afterHooks = {}

    it 'should return true if in both before and after hooks', ->
      hooks.beforeHooks =
        foo: (test, done) ->
          done()
      hooks.afterHooks =
        foo: (test, done) ->
          done()

      assert.ok hooks.hasName 'foo'

      hooks.beforeHooks = {}
      hooks.afterHooks = {}

    it 'should return false if in neither before nor after hooks', ->
      assert.notOk hooks.hasName 'foo'


  describe 'when running hooks', () ->

    beforeHook = ''
    afterHook = ''

    beforeEach () ->
      beforeHook = sinon.stub()
      beforeHook.callsArg(1)

      afterHook = sinon.stub()
      afterHook.callsArg(1)

      hooks.beforeHooks =
        'GET /machines -> 200': [beforeHook]
      hooks.afterHooks =
        'GET /machines -> 200': [afterHook]

    afterEach () ->
      hooks.beforeHooks = {}
      hooks.afterHooks = {}
      beforeHook = ''
      afterHook = ''

    describe 'with correponding test', () ->

      test = new TestStub()
      test.name = 'GET /machines -> 200'
      test.request.server = 'http://abao.io'
      test.request.path = '/machines'
      test.request.method = 'GET'
      test.request.params =
        param: 'value'
      test.request.query =
        q: 'value'
      test.request.headers =
        key: 'value'
      test.response.status = 200
      test.response.schema = """
        [
          type: 'string'
          name: 'string'
        ]
      """

      describe 'on before hook', () ->
        beforeEach (done) ->
          hooks.runBefore test, done

        it 'should run hook', ->
          assert.ok beforeHook.called

        it 'should pass #test to hook', ->
          assert.ok beforeHook.calledWith(test)

      describe 'on after hook', () ->
        beforeEach (done) ->
          hooks.runAfter test, done

        it 'should run hook', ->
          assert.ok afterHook.called

        it 'should pass #test to hook', ->
          assert.ok afterHook.calledWith(test)

    describe 'with incorreponding test', () ->

      test = new TestStub()
      test.name = 'POST /machines -> 201'
      test.request.server = 'http://abao.io'
      test.request.path = '/machines'
      test.request.method = 'POST'
      test.request.params =
        param: 'value'
      test.request.query =
        q: 'value'
      test.request.headers =
        key: 'value'
      test.response.status = 201
      test.response.schema = """
        type: 'string'
        name: 'string'
      """

      describe 'on before hook', () ->
        beforeEach (done) ->
          hooks.runBefore test, done

        it 'should not run hook', ->
          assert.ok beforeHook.notCalled

      describe 'on after hook', () ->
        beforeEach (done) ->
          hooks.runAfter test, done

        it 'should not run hook', ->
          assert.ok afterHook.notCalled
