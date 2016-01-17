chai = require 'chai'
sinon = require 'sinon'
sinonChai = require 'sinon-chai'
_ = require 'underscore'
mocha = require 'mocha'
mute = require 'mute'
proxyquire = require('proxyquire').noCallThru()

TestFactory = require '../../lib/test'

hooksStub = require '../../lib/hooks'
suiteStub = ''

TestRunner = proxyquire '../../lib/test-runner', {
  'mocha': mocha,
  'hooks': hooksStub
}


assert = chai.assert
should = chai.should()
chai.use(sinonChai);

runner = null

describe 'Test Runner', ->

  describe '#run', ->

    describe 'when test is valid', ->

      runner = ''
      beforeAllHook = ''
      afterAllHook = ''
      beforeHook = ''
      afterHook = ''
      runCallback = ''
      testFactory = new TestFactory()
      test = testFactory.create()
      test.name = 'GET /machines -> 200'
      test.request.path = '/machines'
      test.request.method = 'GET'
      test.response.status = 200
      test.response.schema = """[
        type: 'string'
        name: 'string'
      ]"""

      before (done) ->
        config = 
          server: 'http://abao.io'
        runner = new TestRunner config

        runCallback = sinon.stub()
        runCallback(done)
        runCallback.yield()

        beforeAllHook = sinon.stub()
        beforeAllHook.callsArg(0)
        afterAllHook = sinon.stub()
        afterAllHook.callsArg(0)

        hooksStub.beforeAllHooks = [beforeAllHook]
        hooksStub.afterAllHooks = [afterAllHook]

        beforeHook = sinon.stub()
        beforeHook.callsArg(1)
        hooksStub.beforeHooks[test.name] = beforeHook

        mochaStub = runner.mocha
        originSuiteCreate = mocha.Suite.create
        sinon.stub mocha.Suite, 'create', (parent, title) ->
          suiteStub = originSuiteCreate.call(mocha.Suite, parent, title)

          # Stub suite
          originSuiteBeforeAll = suiteStub.beforeAll
          originSuiteAfterAll = suiteStub.afterAll
          sinon.stub suiteStub, 'beforeAll', (title, fn) ->
            beforeHook = fn
            originSuiteBeforeAll.call(suiteStub, title, fn)
          sinon.stub suiteStub, 'afterAll', (title, fn) ->
            afterHook = fn
            originSuiteAfterAll.call(suiteStub, title, fn)

          suiteStub

        sinon.stub mochaStub, 'run', (callback) ->
          callback(0)

        sinon.spy mochaStub.suite, 'beforeAll'
        sinon.spy mochaStub.suite, 'afterAll'

        sinon.stub hooksStub, 'runBefore', (test, callback) ->
          callback()
        sinon.stub hooksStub, 'runAfter', (test, callback) ->
          callback()

        runner.run [test], hooksStub, runCallback

      after ->
        hooksStub.beforeAllHooks = [beforeAllHook]
        hooksStub.afterAllHooks = [afterAllHook]

        mochaStub = runner.mocha
        mochaStub.run.restore()
        mocha.Suite.create.restore()

        hooksStub.runBefore.restore()
        hooksStub.runAfter.restore()

        runCallback = ''

      it 'should generate beforeAll hooks', ->
        mochaStub = runner.mocha
        assert.ok mochaStub.suite.beforeAll.called
        assert.ok mochaStub.suite.afterAll.called

      it 'should run mocha', ->
        assert.ok runner.mocha.run.calledOnce

      it 'should invoke callback with failures', ->
        runCallback.should.be.calledWith null, 0

      it 'should generated mocha suite', ->
        suites = runner.mocha.suite.suites
        assert.equal suites.length, 1
        assert.equal suites[0].title, 'GET /machines -> 200'

      it 'should generated mocha test', ->
        tests = runner.mocha.suite.suites[0].tests
        assert.equal tests.length, 1
        assert.notOk tests[0].pending

      it 'should generated hook of suite', ->
        assert.ok suiteStub.beforeAll.called
        assert.ok suiteStub.afterAll.called

      # describe 'when executed hooks', ->
      #   before (done) ->
      #
      #   it 'should executed hooks', ->
      #   # it 'should generated before hook', ->
      #     assert.ok hooksStub.runBefore.calledWith(test)
        #
        # it 'should call after hook', ->
        #   assert.ok hooksStub.runAfter.calledWith(test)

    describe 'Interact with #test', ->

      test = ''
      runner = ''

      before (done) ->
        testFactory = new TestFactory()
        test = testFactory.create()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'
        test.response.status = 200
        test.response.schema = """[
          type: 'string'
          name: 'string'
        ]"""

        config = 
          server: 'http://abao.io'
        runner = new TestRunner config
        sinon.stub test, 'run', (callback) ->
           callback()

        # Mute stdout/stderr
        mute (unmute) ->
          runner.run [test], hooksStub, ->
            unmute()
            done()

      after ->
        test.run.restore()

      it 'should called #test.run', ->
        assert.ok test.run.calledOnce

    describe 'when test has no respones code', ->
      before (done) ->

        testFactory = new TestFactory()
        test = testFactory.create()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'

        config = 
          server: 'http://localhost:3000'

        runner = new TestRunner config
        sinon.stub runner.mocha, 'run', (callback) -> callback()
        sinon.stub test, 'run', (callback) -> callback()

        runner.run [test], hooksStub, done

      after ->
        runner.mocha.run.restore()

      it 'should run mocha', ->
        assert.ok runner.mocha.run.called

      it 'should generated mocha suite', ->
        suites = runner.mocha.suite.suites
        assert.equal suites.length, 1
        assert.equal suites[0].title, 'GET /machines -> 200'

      it 'should generated pending mocha test', ->
        tests = runner.mocha.suite.suites[0].tests
        assert.equal tests.length, 1
        assert.ok tests[0].pending

    describe 'when test has no response schema', ->
      before (done) ->

        testFactory = new TestFactory()
        test = testFactory.create()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'
        test.response.status = 200

        config = 
          server: 'http://localhost:3000'

        runner = new TestRunner config
        sinon.stub runner.mocha, 'run', (callback) -> callback()
        sinon.stub test, 'run', (callback) -> callback()

        runner.run [test], hooksStub, done

      after ->
        runner.mocha.run.restore()

      it 'should run mocha', ->
        assert.ok runner.mocha.run.called

      it 'should generated mocha suite', ->
        suites = runner.mocha.suite.suites
        assert.equal suites.length, 1
        assert.equal suites[0].title, 'GET /machines -> 200'

      it 'should not generated pending mocha test', ->
        tests = runner.mocha.suite.suites[0].tests
        assert.equal tests.length, 1
        assert.notOk tests[0].pending

    describe 'when test throws AssertionError', ->

      afterAllHook = ''

      before (done) ->

        testFactory = new TestFactory()
        test = testFactory.create()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'
        test.response.status = 200

        afterAllHook = sinon.stub()
        afterAllHook.callsArg(0)

        hooksStub.afterAllHooks = [afterAllHook]

        config = 
          server: 'http://localhost:3000'

        runner = new TestRunner config
        # sinon.stub runner.mocha, 'run', (callback) -> callback()
        testStub = sinon.stub test, 'run'
        testStub.throws('AssertionError')

        # Mute stdout/stderr
        mute (unmute) ->
          runner.run [test], hooksStub, ->
            unmute()
            done()

      after ->
        afterAllHook = ''

      it 'should call afterAll hook', ->
        afterAllHook.should.have.been.called

    describe 'when beforeAllHooks throws Uncaught Error', ->

      beforeAllHook = ''
      afterAllHook = ''

      before (done) ->

        testFactory = new TestFactory()
        test = testFactory.create()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'
        test.response.status = 200

        beforeAllHook = sinon.stub()
        beforeAllHook.throws('Error')
        afterAllHook = sinon.stub()
        afterAllHook.callsArg(0)

        hooksStub.beforeAllHooks = [beforeAllHook]
        hooksStub.afterAllHooks = [afterAllHook]

        config = 
          server: 'http://localhost:3000'

        runner = new TestRunner config
        sinon.stub test, 'run', (callback) ->
          callback()

        # Mute stdout/stderr
        mute (unmute) ->
          runner.run [test], hooksStub, ->
            unmute()
            done()

      after ->
        beforeAllHook = ''
        afterAllHook = ''

      it 'should call afterAll hook', ->
        afterAllHook.should.have.been.called

  describe '#run with options', ->

    describe 'list all tests with `names`', ->
      before (done) ->

        testFactory = new TestFactory()
        test = testFactory.create()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'
        test.response.status = 200
        test.response.schema = """[
          type: 'string'
          name: 'string'
        ]"""

        options =
          names: true

        config = 
          server: 'http://localhost:3000'
          options: options

        runner = new TestRunner config
        sinon.stub runner.mocha, 'run', (callback) -> callback()
        sinon.spy console, 'log'

        # Mute stdout/stderr
        mute (unmute) ->
          runner.run [test], hooksStub, ->
            unmute()
            done()

      after ->
        runner.mocha.run.restore()
        console.log.restore()

      it 'should not run mocha', ->
        assert.notOk runner.mocha.run.called

      it 'should print tests', ->
        assert.ok console.log.calledWith('GET /machines -> 200')

    describe 'add additional headers with `headers`', ->

      recievedTest = ''
      header = ''

      before (done) ->
        testFactory = new TestFactory()
        test = testFactory.create()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'
        test.response.status = 200
        test.response.schema = {}

        header =
          key: 'value'

        config = 
          server: 'http://localhost:3000'
          options: {header}

        runner = new TestRunner config
        sinon.stub runner.mocha, 'run', (callback) ->
          recievedTest = _.clone(test)
          callback()

        runner.run [test], hooksStub, done

      after ->
        runner.mocha.run.restore()

      it 'should run mocha', ->
        assert.ok runner.mocha.run.called

      it 'should add headers into test', ->
        assert.deepEqual recievedTest.request.headers, header

    describe 'run test with hooks only indicated by `hooks-only`', ->

      testFactory = new TestFactory()
      test = testFactory.create()
      test.name = 'GET /machines -> 200'
      test.request.path = '/machines'
      test.request.method = 'GET'
      test.response.status = 200
      test.response.schema = {}

      suiteStub = ''

      before (done) ->

        options =
          'hooks-only': true

        config = 
          server: 'http://localhost:3000'
          options: options

        runner = new TestRunner config 

        mochaStub = runner.mocha
        originSuiteCreate = mocha.Suite.create
        sinon.stub mocha.Suite, 'create', (parent, title) ->
          suiteStub = originSuiteCreate.call(mocha.Suite, parent, title)

          # Stub suite
          sinon.spy suiteStub, 'addTest'
          sinon.spy suiteStub, 'beforeAll'
          sinon.spy suiteStub, 'afterAll'

          suiteStub

        sinon.stub mochaStub, 'run', (callback) ->
          callback()

        runner.run [test], hooksStub, done

      after ->
        runner.mocha.run.restore()
        mocha.Suite.create.restore()
        suiteStub.addTest.restore()
        suiteStub.beforeAll.restore()
        suiteStub.afterAll.restore()

      it 'should run mocha', ->
        assert.ok runner.mocha.run.called

      it 'should add a pending test', ->
        # TODO(quanlong): Implement this test
        # console.log suiteStub.addTest.printf('%n-%c-%C')
        # assert.ok suiteStub.addTest.calledWithExactly('GET /machines -> 200')
