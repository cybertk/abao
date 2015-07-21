{assert} = require 'chai'
sinon = require 'sinon'
ramlParser = require 'raml-parser'

proxyquire = require('proxyquire').noCallThru()

mochaStub = require 'mocha'

Test = require '../../lib/test'
hooks = require '../../lib/hooks'
addTests = proxyquire '../../lib/add-tests', {
  'mocha': mochaStub
}

describe '#addTests', ->

  describe '#run', ->

    describe 'when raml contains single get', ->

      tests = []
      callback = ''

      before (done) ->
        ramlParser.loadFile("#{__dirname}/../fixtures/single-get.raml")
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback
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
        assert.deepEqual req.headers,
          'Abao-API-Key': 'abcdef'
        assert.deepEqual req.body, {}
        assert.equal req.method, 'GET'

      it 'should setup test.response', ->
        res = tests[0].response

        assert.equal res.status, 200
        schema = res.schema
        assert.equal schema.items.properties.type.type, 'string'
        assert.equal schema.items.properties.name.type, 'string'
        assert.isNull res.headers
        assert.isNull res.body

    describe 'when raml contains one GET and one POST', ->

      tests = []
      callback = ''

      before (done) ->

        ramlParser.loadFile("#{__dirname}/../fixtures/1-get-1-post.raml")
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback
        , done
      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should added 2 test', ->
        assert.lengthOf tests, 2

      it 'should setup test.request of POST', ->
        req = tests[1].request

        assert.equal req.path, '/machines'
        assert.deepEqual req.params, {}
        assert.deepEqual req.query, {}
        assert.deepEqual req.headers,
          'Content-Type': 'application/json'
        assert.deepEqual req.body,
          type: 'Kulu'
          name: 'Mike'
        assert.equal req.method, 'POST'

      it 'should setup test.response of POST', ->
        res = tests[1].response

        assert.equal res.status, 201
        schema = res.schema
        assert.equal schema.properties.type.type, 'string'
        assert.equal schema.properties.name.type, 'string'
        assert.isNull res.headers
        assert.isNull res.body

    describe 'when raml includes multiple referencing schemas', ->

      tests = []
      callback = ''

      before (done) ->

        ramlParser.loadFile("#{__dirname}/../fixtures/ref_other_schemas.raml")
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback
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
        assert.deepEqual req.body, {}
        assert.equal req.method, 'GET'

      it 'should setup test.response', ->
        res = tests[0].response
        
        assert.equal res.status, 200
        assert.equal res.schema?.properties?.chick?.type, "string"
        assert.isNull res.headers
        assert.isNull res.body

    describe 'when raml has inline and included schemas', ->

      tests = []
      callback = ''

      before (done) ->

        ramlParser.loadFile("#{__dirname}/../fixtures/inline_and_included_schemas.raml")
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback
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
        assert.deepEqual req.body, {}
        assert.equal req.method, 'GET'

      it 'should setup test.response', ->
        res = tests[0].response
        
        assert.equal res.status, 200
        assert.equal res.schema?.properties?.type["$ref"], "type2"
        assert.isNull res.headers
        assert.isNull res.body

    describe 'when raml contains three-levels endpoints', ->

      tests = []
      callback = ''

      before (done) ->

        ramlParser.loadFile("#{__dirname}/../fixtures/three-levels.raml")
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback
        , done

      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should added 3 test', ->
        assert.lengthOf tests, 3

      it 'should set test.name', ->
        assert.equal tests[0].name, 'GET /machines -> 200'
        assert.equal tests[1].name, 'DELETE /machines/{machine_id} -> 204'
        assert.equal tests[2].name, 'GET /machines/{machine_id}/parts -> 200'

      it 'should set request.param of test 1', ->
        test = tests[1]
        assert.deepEqual test.request.params,
          machine_id: '1'

      it 'should set request.param of test 2', ->
        test = tests[2]
        assert.deepEqual test.request.params,
          machine_id: '1'

    describe 'when raml has resource not defined method', ->

      tests = []
      callback = ''

      before (done) ->

        ramlParser.loadFile("#{__dirname}/../fixtures/no-method.raml")
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback
        , done

      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should added 1 test', ->
        assert.lengthOf tests, 1

      it 'should set test.name', ->
        assert.equal tests[0].name, 'GET /root/machines -> 200'

    describe 'when raml has invalid request body example', ->

      tests = []
      callback = ''

      before (done) ->

        raml = """
        #%RAML 0.8

        title: World Music API
        baseUri: http://example.api.com/{version}
        version: v1
        mediaType: application/json

        /machines:
          post:
            body:
              example: 'invalid-json'
            responses:
              204:
        """
        ramlParser.load(raml)
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          sinon.stub console, 'warn'
          addTests data, tests, hooks, callback
        , done

      after ->
        tests = []
        console.warn.restore()

      it 'should run callback', ->
        assert.ok callback.called

      it 'should give a warning', ->
        assert.ok console.warn.called

      it 'should added 1 test', ->
        assert.lengthOf tests, 1
        assert.equal tests[0].name, 'POST /machines -> 204'
