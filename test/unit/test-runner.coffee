{assert} = require 'chai'
sinon = require 'sinon'
request = require 'request'
_ = require 'underscore'
proxyquire = require('proxyquire').noCallThru()

Test = require '../../lib/test'

TestRunner = proxyquire '../../lib/test-runner', {
}


runner = null

describe 'Test Runner', ->

  describe '#run', ->

    describe 'and single test', ->

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
        tests = [test]

        runner = new TestRunner "http://abao.io"
        sinon.stub runner.mocha, 'run', (callback) -> callback()

        runner.run tests, done

      after ->
        runner.mocha.run.restore()

      it 'should run mocha', ->
        assert.ok runner.mocha.run.calledOnce

      it 'should generated mocha suite', ->
        suites = runner.mocha.suite.suites
        assert.equal suites.length, 1
        assert.equal suites[0].title, 'GET /machines -> 200'

      it 'should generated mocha test', ->
        tests = runner.mocha.suite.suites[0].tests
        assert.equal tests.length, 1
        assert.notOk tests[0].pending

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

        runner.run [test], done

      after ->
        test.run.restore()

      it 'should called #test.run', ->
        assert.ok test.run.calledOnce

    describe 'and test has no schema', ->
      before (done) ->

        test = new Test()
        test.name = 'GET /machines -> 200'
        test.request.path = '/machines'
        test.request.method = 'GET'
        test.response.status = 200

        runner = new TestRunner "http://localhost:3000"
        sinon.stub runner.mocha, 'run', (callback) -> callback()
        sinon.stub test, 'run', (callback) -> callback()

        runner.run [test], done

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

        runner.run [test], done

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

        runner.run [test], done

      after ->
        runner.mocha.run.restore()

      it 'should run mocha', ->
        assert.ok runner.mocha.run.called

      it 'should add headers into test', ->
        assert.deepEqual recievedTest.request.headers, header
