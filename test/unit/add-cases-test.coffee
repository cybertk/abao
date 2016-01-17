{assert} = require 'chai'
sinon = require 'sinon'
ramlParser = require 'raml-parser'

proxyquire = require('proxyquire').noCallThru()

mochaStub = require 'mocha'

TestFactory = require '../../lib/test'
addCases = proxyquire '../../lib/add-cases', {
  'mocha': mochaStub
}

baseCaseFolder = "#{__dirname}/../fixtures/cases"

describe '#addCases', ->

  describe '#run', ->

    describe 'when raml contains single get', ->

      tests = []
      testFactory = new TestFactory()
      callback = ''

      before (done) ->

        ramlParser.loadFile("#{__dirname}/../fixtures/single-get.raml")
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addCases baseCaseFolder, data, tests, callback, testFactory
        , done
      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should added 1 test', ->
        assert.lengthOf tests, 1

      it 'should set test.name', ->
        assert.equal tests[0].name, 'Case: GET /machines -> 200'

      it 'should setup test.request', ->
        req = tests[0].request

        assert.equal req.path, '/machines'
        assert.deepEqual req.params, {}
        assert.deepEqual req.query,
          page: 1
          'per-page': 10
        assert.deepEqual req.headers,
          'Abao-API-Key': 'test'
          'Content-Type': 'application/json'
        assert.deepEqual req.body, {}
        assert.equal req.method, 'GET'

      it 'should setup test.response', ->
        res = tests[0].response

        assert.equal res.status, 200
        assert.deepEqual res.body, 
          type: 'Kulu'
          name: 'Mike'
        assert.ok not res.headers
