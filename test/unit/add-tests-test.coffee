{assert} = require 'chai'
sinon = require 'sinon'
ramlParser = require 'raml-parser'

proxyquire = require('proxyquire').noCallThru()

mochaStub = require 'mocha'

TestFactory = require '../../lib/test'
hooks = require '../../lib/hooks'
addTests = proxyquire '../../lib/add-tests', {
  'mocha': mochaStub
}

FIXTURE_DIR = "#{__dirname}/../fixtures"
RAML_DIR = "#{FIXTURE_DIR}"


describe '#addTests', ->

  describe '#run', ->

    describe 'when RAML contains single GET', ->

      tests = []
      testFactory = new TestFactory()
      callback = ''

      before (done) ->
        ramlFile = "#{RAML_DIR}/single-get.raml"
        ramlParser.loadFile(ramlFile)
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback, testFactory
        , done
      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should add 1 test', ->
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
        req.body.should.be.empty
        assert.equal req.method, 'GET'

      it 'should setup test.response', ->
        res = tests[0].response

        assert.equal res.status, 200
        schema = res.schema
        assert.equal schema.items.properties.type.type, 'string'
        assert.equal schema.items.properties.name.type, 'string'
        assert.isNull res.headers
        assert.isNull res.body

    describe 'when RAML contains one GET and one POST', ->

      tests = []
      testFactory = new TestFactory()
      callback = ''

      before (done) ->

        ramlFile = "#{RAML_DIR}/1-get-1-post.raml"
        ramlParser.loadFile(ramlFile)
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback, testFactory
        , done
      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should add 2 tests', ->
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

    describe 'when RAML includes multiple referencing schemas', ->

      tests = []
      testFactory = new TestFactory
      callback = ''

      before (done) ->

        ramlFile = "#{RAML_DIR}/ref_other_schemas.raml"
        ramlParser.loadFile(ramlFile)
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback, testFactory
        , done
      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should add 1 test', ->
        assert.lengthOf tests, 1

      it 'should set test.name', ->
        assert.equal tests[0].name, 'GET /machines -> 200'

      it 'should setup test.request', ->
        req = tests[0].request

        assert.equal req.path, '/machines'
        assert.deepEqual req.params, {}
        assert.deepEqual req.query, {}
        req.body.should.be.empty
        assert.equal req.method, 'GET'

      it 'should setup test.response', ->
        res = tests[0].response

        assert.equal res.status, 200
        assert.equal res.schema?.properties?.chick?.type, "string"
        assert.isNull res.headers
        assert.isNull res.body

    describe 'when RAML has inline and included schemas', ->

      tests = []
      testFactory = new TestFactory
      callback = ''

      before (done) ->

        ramlFile = "#{RAML_DIR}/inline_and_included_schemas.raml"
        ramlParser.loadFile(ramlFile)
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback, testFactory
        , done
      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should add 1 test', ->
        assert.lengthOf tests, 1

      it 'should set test.name', ->
        assert.equal tests[0].name, 'GET /machines -> 200'

      it 'should setup test.request', ->
        req = tests[0].request

        assert.equal req.path, '/machines'
        assert.deepEqual req.params, {}
        assert.deepEqual req.query, {}
        req.body.should.be.empty
        assert.equal req.method, 'GET'

      it 'should setup test.response', ->
        res = tests[0].response

        assert.equal res.status, 200
        assert.equal res.schema?.properties?.type["$ref"], "type2"
        assert.isNull res.headers
        assert.isNull res.body

    describe 'when RAML contains three-levels endpoints', ->

      tests = []
      testFactory = new TestFactory()
      callback = ''

      before (done) ->

        ramlFile = "#{RAML_DIR}/three-levels.raml"
        ramlParser.loadFile(ramlFile)
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback, testFactory
        , done

      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should add 3 tests', ->
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

    describe 'when RAML has resource not defined method', ->

      tests = []
      testFactory = new TestFactory()
      callback = ''

      before (done) ->

        ramlFile = "#{RAML_DIR}/no-method.raml"
        ramlParser.loadFile(ramlFile)
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback, testFactory
        , done

      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should add 1 test', ->
        assert.lengthOf tests, 1

      it 'should set test.name', ->
        assert.equal tests[0].name, 'GET /root/machines -> 200'

    describe 'when RAML has invalid request body example', ->

      tests = []
      testFactory = new TestFactory()
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
          addTests data, tests, hooks, callback, testFactory
        , done

      after ->
        tests = []
        console.warn.restore()

      it 'should run callback', ->
        assert.ok callback.called

      it 'should give a warning', ->
        assert.ok console.warn.called

      it 'should add 1 test', ->
        assert.lengthOf tests, 1
        assert.equal tests[0].name, 'POST /machines -> 204'

    describe 'when RAML media type uses a JSON-suffixed vendor tree subtype', ->
      tests = []
      testFactory = new TestFactory()
      callback = ''

      before (done) ->
        ramlFile = "#{RAML_DIR}/vendor-content-type.raml"
        ramlParser.loadFile(ramlFile)
        .then (data) ->
          callback = sinon.stub()
          callback.returns(done())

          addTests data, tests, hooks, callback, testFactory
        , done
      after ->
        tests = []

      it 'should run callback', ->
        assert.ok callback.called

      it 'should add 1 test', ->
        assert.lengthOf tests, 1

      it 'should setup test.request of PATCH', ->
        req = tests[0].request

        assert.equal req.path, '/{songId}'
        assert.deepEqual req.params,
          songId: 'mike-a-beautiful-day'
        assert.deepEqual req.query, {}
        assert.deepEqual req.headers,
          'Content-Type': 'application/vnd.api+json'
        assert.deepEqual req.body,
          title: 'A Beautiful Day'
          artist: 'Mike'
        assert.equal req.method, 'PATCH'

      it 'should setup test.response of PATCH', ->
        res = tests[0].response

        assert.equal res.status, 200
        schema = res.schema
        assert.equal schema.properties.title.type, 'string'
        assert.equal schema.properties.artist.type, 'string'

