{assert} = require 'chai'
sinon = require 'sinon'
ramlParser = require 'raml-parser'

proxyquire = require('proxyquire').noCallThru()

mochaStub = require 'mocha'

Test = require '../../lib/test'
addTests = proxyquire '../../lib/add-tests', {
  'mocha': mochaStub
}

describe '#addTests', ->

  describe '#run', ->

    describe 'when single get raml', ->

      tests = []
      callback = ''

      before (done) ->

        ramlParser.loadFile("#{__dirname}/../fixtures/single-get.raml")
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, callback
        , done
      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should added 1 test', ->
        assert.lengthOf tests, 1

      it 'should set test.name', ->
        assert.equal tests[0].name, 'GET /machines -> 200'

      it 'should setup test.request', ->
        req = tests[0].request

        assert.equal req.path, '/machines'
        assert.deepEqual req.params, {}
        assert.deepEqual req.query, {}
        assert.deepEqual req.headers, {}
        assert.equal req.method, 'GET'

      it 'should setup test.response', ->
        res = tests[0].response

        assert.equal res.status, 200
        assert.equal res.schema, """[
          type: 'string'
          name: 'string'
        ]

        """
        assert.isNull res.headers
        assert.isNull res.body

    describe 'when two-level raml', ->

      tests = []
      callback = ''

      before (done) ->

        ramlParser.loadFile("#{__dirname}/../fixtures/two-levels.raml")
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, callback
        , done

      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should added 2 test', ->
        assert.lengthOf tests, 2

      it 'should set test.name', ->
        assert.equal tests[0].name, 'GET /machines -> 200'
        assert.equal tests[1].name, 'GET /machines/{machine_id} -> 200'
