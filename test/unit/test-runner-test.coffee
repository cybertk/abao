chai = require 'chai'
_ = require 'lodash'
mocha = require 'mocha'
mute = require 'mute'
proxyquire = require('proxyquire').noCallThru()
sinon = require 'sinon'
sinonChai = require 'sinon-chai'

assert = chai.assert
expect = chai.expect
should = chai.should()
chai.use sinonChai

pkg = require '../../package'
TestFactory = require '../../lib/test'
hooksStub = require '../../lib/hooks'
suiteStub = undefined

TestRunner = proxyquire '../../lib/test-runner', {
  'mocha': mocha,
  'hooks': hooksStub
}

ABAO_IO_SERVER = 'http://abao.io'
SERVER = 'http://localhost:3000'


describe 'Test Runner', () ->
  'use strict'

  runner = undefined
  test = undefined

  createStdTest = () ->
    testname = 'GET /machines -> 200'
    testFactory = new TestFactory()
    stdTest = testFactory.create testname, undefined
    stdTest.request.path = '/machines'
    stdTest.request.method = 'GET'
    return stdTest


  describe '#run', () ->

    describe 'when test is valid', () ->

      beforeAllHook = undefined
      afterAllHook = undefined
      beforeHook = undefined
      afterHook = undefined
      runCallback = undefined

      before (done) ->
        test = createStdTest()
        test.response.status = 200
        test.response.schema = """[
          type: 'string'
          name: 'string'
        ]"""

        options =
          server: "#{ABAO_IO_SERVER}"

        runner = new TestRunner options, ''

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
        sinon.stub mocha.Suite, 'create'
          .callsFake (parent, title) ->
            suiteStub = originSuiteCreate.call(mocha.Suite, parent, title)

            # Stub suite
            originSuiteBeforeAll = suiteStub.beforeAll
            originSuiteAfterAll = suiteStub.afterAll
            sinon.stub suiteStub, 'beforeAll'
              .callsFake (title, fn) ->
                beforeHook = fn
                originSuiteBeforeAll.call(suiteStub, title, fn)
            sinon.stub suiteStub, 'afterAll'
              .callsFake (title, fn) ->
                afterHook = fn
                originSuiteAfterAll.call(suiteStub, title, fn)

            suiteStub

        sinon.stub mochaStub, 'run'
          .callsFake (callback) ->
            callback(0)

        sinon.spy mochaStub.suite, 'beforeAll'
        sinon.spy mochaStub.suite, 'afterAll'

        sinon.stub hooksStub, 'runBefore'
          .callsFake (test, callback) ->
            callback()
        sinon.stub hooksStub, 'runAfter'
          .callsFake (test, callback) ->
            callback()

        runner.run [test], hooksStub, runCallback

      after () ->
        hooksStub.beforeAllHooks = [beforeAllHook]
        hooksStub.afterAllHooks = [afterAllHook]

        mochaStub = runner.mocha
        mochaStub.run.restore()
        mocha.Suite.create.restore()

        hooksStub.runBefore.restore()
        hooksStub.runAfter.restore()

        runCallback = undefined
        runner = undefined
        test = undefined

      it 'should generate beforeAll hooks', () ->
        mochaStub = runner.mocha
        assert.ok mochaStub.suite.beforeAll.called
        assert.ok mochaStub.suite.afterAll.called

      it 'should run mocha', () ->
        assert.ok runner.mocha.run.calledOnce

      it 'should invoke callback with failures', () ->
        runCallback.should.be.calledWith null, 0

      it 'should generate mocha suite', () ->
        suites = runner.mocha.suite.suites
        assert.equal suites.length, 1
        assert.equal suites[0].title, 'GET /machines -> 200'

      it 'should generate mocha test', () ->
        tests = runner.mocha.suite.suites[0].tests
        assert.equal tests.length, 1
        assert.notOk tests[0].pending

      it 'should generate hook of suite', () ->
        assert.ok suiteStub.beforeAll.called
        assert.ok suiteStub.afterAll.called

      # describe 'when executed hooks', () ->
      #   before (done) ->
      #
      #   it 'should execute hooks', () ->
      #   # it 'should generate before hook', () ->
      #     assert.ok hooksStub.runBefore.calledWith(test)
        #
        # it 'should call after hook', () ->
        #   assert.ok hooksStub.runAfter.calledWith(test)


    describe 'Interact with #test', () ->

      before (done) ->
        test = createStdTest()
        test.response.status = 200
        test.response.schema = """[
          type: 'string'
          name: 'string'
        ]"""

        options =
          server: "#{ABAO_IO_SERVER}"

        runner = new TestRunner options, ''
        sinon.stub test, 'run'
          .callsFake (callback) ->
            callback()

        # Mute stdout/stderr
        mute (unmute) ->
          runner.run [test], hooksStub, () ->
            unmute()
            done()

      after () ->
        test.run.restore()
        runner = undefined
        test = undefined

      it 'should call #test.run', () ->
        assert.ok test.run.calledOnce


    describe 'when test has no response code', () ->

      before (done) ->
        testFactory = new TestFactory()
        test = testFactory.create()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'

        options =
          server: "#{SERVER}"

        runner = new TestRunner options, ''
        sinon.stub runner.mocha, 'run'
          .callsFake (callback) ->
            callback()
        sinon.stub test, 'run'
          .callsFake (callback) ->
            callback()

        runner.run [test], hooksStub, done

      after () ->
        runner.mocha.run.restore()
        runner = undefined
        test = undefined

      it 'should run mocha', () ->
        assert.ok runner.mocha.run.called

      it 'should generate mocha suite', () ->
        suites = runner.mocha.suite.suites
        assert.equal suites.length, 1
        assert.equal suites[0].title, 'GET /machines -> 200'

      it 'should generate pending mocha test', () ->
        tests = runner.mocha.suite.suites[0].tests
        assert.equal tests.length, 1
        assert.ok tests[0].pending


    describe 'when test skipped in hooks', () ->

      before (done) ->
        test = createStdTest()
        test.response.status = 200
        test.response.schema = """[
          type: 'string'
          name: 'string'
        ]"""

        options =
          server: "#{SERVER}"

        runner = new TestRunner options, ''
        sinon.stub runner.mocha, 'run'
          .callsFake (callback) ->
            callback()
        sinon.stub test, 'run'
          .callsFake (callback) ->
            callback()
        hooksStub.skippedTests = [test.name]
        runner.run [test], hooksStub, done

      after () ->
        hooksStub.skippedTests = []
        runner.mocha.run.restore()
        runner = undefined
        test = undefined

      it 'should run mocha', () ->
        assert.ok runner.mocha.run.called

      it 'should generate mocha suite', () ->
        suites = runner.mocha.suite.suites
        assert.equal suites.length, 1
        assert.equal suites[0].title, 'GET /machines -> 200'

      it 'should generate pending mocha test', () ->
        tests = runner.mocha.suite.suites[0].tests
        assert.equal tests.length, 1
        assert.ok tests[0].pending


    describe 'when test has no response schema', () ->

      before (done) ->
        test = createStdTest()
        test.response.status = 200

        options =
          server: "#{SERVER}"

        runner = new TestRunner options, ''
        sinon.stub runner.mocha, 'run'
          .callsFake (callback) ->
            callback()
        sinon.stub test, 'run'
          .callsFake (callback) ->
            callback()

        runner.run [test], hooksStub, done

      after () ->
        runner.mocha.run.restore()
        runner = undefined
        test = undefined

      it 'should run mocha', () ->
        assert.ok runner.mocha.run.called

      it 'should generate mocha suite', () ->
        suites = runner.mocha.suite.suites
        assert.equal suites.length, 1
        assert.equal suites[0].title, 'GET /machines -> 200'

      it 'should not generate pending mocha test', () ->
        tests = runner.mocha.suite.suites[0].tests
        assert.equal tests.length, 1
        assert.notOk tests[0].pending


    describe 'when test throws Error', () ->

      afterAllHook = undefined

      before (done) ->
        test = createStdTest()
        test.response.status = 200

        afterAllHook = sinon.stub()
        afterAllHook.callsArg(0)

        hooksStub.afterAllHooks = [afterAllHook]

        options =
          server: "#{SERVER}"

        runner = new TestRunner options, ''
        # sinon.stub runner.mocha, 'run', (callback) -> callback()
        testStub = sinon.stub test, 'run'
        testStub.throws new Error 'thrown from test#run'

        # Mute stdout/stderr
        mute (unmute) ->
          runner.run [test], hooksStub, () ->
            unmute()
            done()

      after () ->
        afterAllHook = undefined
        runner = undefined
        test = undefined

      it 'should call afterAll hook', () ->
        afterAllHook.should.have.been.called


    describe 'when beforeAllHooks throws UncaughtError', () ->

      beforeAllHook = undefined
      afterAllHook = undefined

      before (done) ->
        test = createStdTest()
        test.response.status = 200

        beforeAllHook = sinon.stub()
        beforeAllHook.throws new Error 'thrown from beforeAll hook'
        afterAllHook = sinon.stub()
        afterAllHook.callsArg(0)

        hooksStub.beforeAllHooks = [beforeAllHook]
        hooksStub.afterAllHooks = [afterAllHook]

        options =
          server: "#{SERVER}"

        runner = new TestRunner options, ''
        sinon.stub test, 'run'
          .callsFake (callback) ->
            callback()

        # Mute stdout/stderr
        mute (unmute) ->
          runner.run [test], hooksStub, () ->
            unmute()
            done()

      after () ->
        beforeAllHook = undefined
        afterAllHook = undefined
        runner = undefined
        test = undefined

      it 'should call afterAll hook', () ->
        afterAllHook.should.have.been.called


  describe '#run with options', () ->

    describe 'list all tests with `names`', () ->

      before (done) ->
        test = createStdTest()
        test.response.status = 200
        test.response.schema = """[
          type: 'string'
          name: 'string'
        ]"""

        options =
          names: true

        runner = new TestRunner options, ''
        sinon.stub runner.mocha, 'run'
          .callsFake (callback) ->
            callback()
        sinon.spy console, 'log'

        # Mute stdout/stderr
        mute (unmute) ->
          runner.run [test], hooksStub, () ->
            unmute()
            done()

      after () ->
        console.log.restore()
        runner.mocha.run.restore()
        runner = undefined
        test = undefined

      it 'should not run mocha', () ->
        assert.notOk runner.mocha.run.called

      it 'should print tests', () ->
        assert.ok console.log.calledWith('GET /machines -> 200')


    describe 'add additional headers with `headers`', () ->

      receivedTest = undefined
      headers = undefined

      before (done) ->
        test = createStdTest()
        test.response.status = 200
        test.response.schema = {}

        headers =
          key: 'value'
          'X-Abao-Version': pkg.version

        options =
          server: "#{SERVER}"
          header: headers

        runner = new TestRunner options, ''
        sinon.stub runner.mocha, 'run'
          .callsFake (callback) ->
            receivedTest = _.cloneDeep test
            callback()

        runner.run [test], hooksStub, done

      after () ->
        runner.mocha.run.restore()
        runner = undefined
        test = undefined

      it 'should run mocha', () ->
        assert.ok runner.mocha.run.called

      it 'should add headers into test', () ->
        assert.deepEqual receivedTest.request.headers, headers


    describe 'run test with hooks only indicated by `hooks-only`', () ->

      suiteStub = undefined

      before (done) ->
        test = createStdTest()
        test.response.status = 200
        test.response.schema = {}

        options =
          server: "#{SERVER}"
          'hooks-only': true

        runner = new TestRunner options, ''

        mochaStub = runner.mocha
        originSuiteCreate = mocha.Suite.create
        sinon.stub mocha.Suite, 'create'
          .callsFake (parent, title) ->
            suiteStub = originSuiteCreate.call(mocha.Suite, parent, title)

            # Stub suite
            sinon.spy suiteStub, 'addTest'
            sinon.spy suiteStub, 'beforeAll'
            sinon.spy suiteStub, 'afterAll'

            suiteStub

        sinon.stub mochaStub, 'run'
          .callsFake (callback) ->
            callback()

        runner.run [test], hooksStub, done

      after () ->
        suiteStub.addTest.restore()
        suiteStub.beforeAll.restore()
        suiteStub.afterAll.restore()
        mocha.Suite.create.restore()
        runner.mocha.run.restore()
        runner = undefined
        test = undefined

      it 'should run mocha', () ->
        assert.ok runner.mocha.run.called

      it 'should add a pending test'
        # TODO(quanlong): Implement this test
        # console.log suiteStub.addTest.printf('%n-%c-%C')
        # assert.ok suiteStub.addTest.calledWithExactly('GET /machines -> 200')

