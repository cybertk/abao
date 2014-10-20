chai = require 'chai'
sinon = require 'sinon'
sinonChai = require 'sinon-chai'
_ = require 'underscore'
mocha = require 'mocha'
proxyquire = require('proxyquire').noCallThru()

Test = require '../../src/test'

hooksStub = require '../../src/hooks'
suiteStub = ''

TestRunner = proxyquire '../../src/test-runner', {
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
      mochaCallback = ''
      test = new Test()
      test.name = 'GET /machines -> 200'
      test.request.path = '/machines'
      test.request.method = 'GET'
      test.response.status = 200
      test.response.schema = """[
        type: 'string'
        name: 'string'
      ]"""

      before (done) ->
        runner = new TestRunner "http://abao.io"

        runCallback = sinon.stub()
        runCallback(done)
        runCallback.yield()

        beforeAllHook = sinon.stub()
        beforeAllHook.callsArg(0)
        afterAllHook = sinon.stub()
        afterAllHook.callsArg(0)

        hooksStub.beforeAllHooks = [beforeAllHook]
        hooksStub.afterAllHooks = [afterAllHook]

        mochaCallback = sinon.stub()

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
          mochaCallback()
          callback(0)

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
        mochaCallback = ''

      it 'should run beforeAll hooks before tests', ->
        assert.ok beforeAllHook.calledBefore(runner.mocha.run)

      it 'should run afterAll hooks', ->
        assert.ok afterAllHook.calledAfter(mochaCallback)

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
        test = new Test()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'
        test.response.status = 200
        test.response.schema = """[
          type: 'string'
          name: 'string'
        ]"""

        runner = new TestRunner "http://abao.io"
        sinon.stub test, 'run', (callback) ->
           callback()

        runner.run [test], hooksStub, done

      after ->
        test.run.restore()

      it 'should called #test.run', ->
        assert.ok test.run.calledOnce

    describe 'when test has no respones code', ->
      before (done) ->

        test = new Test()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'

        runner = new TestRunner "http://localhost:3000"
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

        test = new Test()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'
        test.response.status = 200

        runner = new TestRunner "http://localhost:3000"
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

  describe '#run with options', ->

    describe 'list all tests with `names`', ->
      before (done) ->

        test = new Test()
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

        runner = new TestRunner 'http://localhost:3000', options
        sinon.stub runner.mocha, 'run', (callback) -> callback()
        sinon.spy console, 'log'

        runner.run [test], hooksStub, done

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
        test = new Test()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'
        test.response.status = 200
        test.response.schema = {}

        header =
          key: 'value'

        runner = new TestRunner 'http://localhost:3000', {header}
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

      test = new Test()
      test.name = 'GET /machines -> 200'
      test.request.path = '/machines'
      test.request.method = 'GET'
      test.response.status = 200
      test.response.schema = {}

      suiteStub = ''

      before (done) ->

        options =
          'hooks-only': true

        runner = new TestRunner 'http://localhost:3000', options

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
