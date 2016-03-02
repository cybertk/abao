require 'coffee-errors'
sinon = require 'sinon'
{assert} = require 'chai'

TestFactoryStub = require '../../lib/test'

hooks = require '../../lib/hooks'

ABAO_IO_SERVER = 'http://abao.io'

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

  describe 'when adding beforeEach hooks', () ->

    afterEach () ->
      hooks.beforeEachHooks = []
      hooks.beforeHooks = {}

    it 'should add to hook list', () ->
      hooks.beforeEach () ->
      assert.lengthOf hooks.beforeEachHooks, 1

    it 'should invoke registered callbacks', (testDone) ->
      before_called = false
      before_each_called = false
      test_name = "before_test"
      hooks.before test_name, (test, done) ->
        assert.equal test.name, test_name
        before_called = true
        assert.isTrue before_each_called,
            "before_hook should be called after before_each"
        done()

      hooks.beforeEach (test, done) ->
        assert.equal test.name, test_name
        before_each_called = true
        assert.isFalse before_called,
            "before_each should be called before before_hook"
        done()

      hooks.runBefore {name: test_name}, () ->
        assert.isTrue before_each_called, "before_each should have been called"
        assert.isTrue before_called, "before_hook should have been called"
        testDone()

    it 'should work without test-specific before', (testDone) ->
      before_each_called = false
      test_name = "before_test"
      hooks.beforeEach (test, done) ->
        assert.equal test.name, test_name
        before_each_called = true
        done()

      hooks.runBefore {name: test_name}, () ->
        assert.isTrue before_each_called, "before_each should have been called"
        testDone()

  describe 'when adding afterEach hooks', () ->

    afterEach () ->
      hooks.afterEachHooks = []
      hooks.afterHooks = {}

    it 'should add to hook list', () ->
      hooks.afterEach () ->
      assert.lengthOf hooks.afterEachHooks, 1

    it 'should invoke registered callbacks', (testDone) ->
      after_called = false
      after_each_called = false
      test_name = "after_test"
      hooks.after test_name, (test, done) ->
        assert.equal test.name, test_name
        after_called = true
        assert.isFalse after_each_called,
            "after_hook should be called before after_each"
        done()

      hooks.afterEach (test, done) ->
        assert.equal test.name, test_name
        after_each_called = true
        assert.isTrue after_called,
            "after_each should be called after after_hook"
        done()

      hooks.runAfter {name: test_name}, () ->
        assert.isTrue after_each_called, "after_each should have been called"
        assert.isTrue after_called, "after_hook should have been called"
        testDone()

    it 'should work without test-specific after', (testDone) ->
      after_each_called = false
      test_name = "after_test"
      hooks.afterEach (test, done) ->
        assert.equal test.name, test_name
        after_each_called = true
        done()

      hooks.runAfter {name: test_name}, () ->
        assert.isTrue after_each_called, "after_each should have been called"
        testDone()

  describe 'when check has name', () ->

    it 'should return true if in before hooks', ->
      hooks.beforeHooks =
        foo: (test, done) ->
          done()

      assert.ok hooks.hasName 'foo'

      hooks.beforeHooks = {}

    it 'should return true if test name matches regular expression hook', ->
      hooks.beforeHooks =
        'GET /.* -> [200|404]': (test, done) ->
          done()

      assert.ok hooks.hasName 'GET /users -> 200'
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

    describe 'with corresponding GET test', () ->

      testFactory = new TestFactoryStub()
      test = testFactory.create()
      test.name = 'GET /machines -> 200'
      test.request.server = "#{ABAO_IO_SERVER}"
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

    describe 'with corresponding POST test', () ->

      testFactory = new TestFactoryStub()
      test = testFactory.create()
      test.name = 'POST /machines -> 201'
      test.request.server = "#{ABAO_IO_SERVER}"
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

  describe 'when running beforeAll/afterAll', () ->

    funcs = []

    before () ->
      for i in [1..4]
        hook = sinon.stub()
        hook.callsArg(0)
        funcs.push hook

      hooks.beforeAllHooks = [funcs[0], funcs[1]]
      hooks.afterAllHooks = [funcs[2], funcs[3]]

    after () ->
      hooks.beforeAllHooks = []
      hooks.afterAllHooks = []
      funcs = []

    describe 'on beforeAll hook', () ->
      callback = ''

      before (done) ->
        callback = sinon.stub()
        callback.returns(done())

        hooks.runBeforeAll callback

      it 'should invoke callback', ->
        assert.ok callback.calledWithExactly(undefined), callback.printf('%C')

      it 'should run hook', () ->
        assert.ok funcs[0].called
        assert.ok funcs[1].called

    describe 'on afterAll hook', () ->
      callback = ''

      before (done) ->
        callback = sinon.stub()
        callback.returns(done())

        hooks.runAfterAll callback

      it 'should invoke callback', ->
        assert.ok callback.calledWithExactly(undefined), callback.printf('%C')

      it 'should run hook', ->
        assert.ok funcs[2].called
        assert.ok funcs[3].called

  describe 'when successfully adding test hook', () ->

    afterEach () ->
      hooks.contentTests = {}

    test_name = "content_test_test"

    it 'should get added to the set of hooks', () ->
      hooks.test(test_name, () ->)
      assert.isDefined(hooks.contentTests[test_name])

  describe 'adding two content tests fails', () ->
    afterEach () ->
      hooks.contentTests = {}

    test_name = "content_test_test"

    it 'should assert when adding a second content test', () ->
      f = () ->
        hooks.test(test_name, () ->)
      f()
      assert.throw f,
        "Cannot have more than one test with the name: #{test_name}"

