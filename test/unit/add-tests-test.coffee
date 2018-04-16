chai = require 'chai'
mocha = require 'mocha'
proxyquire = require('proxyquire').noCallThru()
ramlParser = require 'raml-parser'
sinon = require 'sinon'
sinonChai = require 'sinon-chai'

assert = chai.assert
expect = chai.expect
should = chai.should()
chai.use sinonChai

TestFactory = require '../../lib/test'
hooks = require '../../lib/hooks'
addTests = proxyquire '../../lib/add-tests', {
  'mocha': mocha
}

FIXTURE_DIR = "#{__dirname}/../fixtures"
RAML_DIR = "#{FIXTURE_DIR}"


describe 'addTests(raml, tests, hooks, parent, callback, factory, sortFirst)', () ->
  'use strict'

  describe 'run', () ->

    describe 'when endpoint specifies a single method', () ->

      tests = []
      testFactory = new TestFactory()
      callback = undefined

      before (done) ->
        ramlFile = "#{RAML_DIR}/machines-single_get.raml"
        ramlParser.loadFile(ramlFile)
          .then (raml) ->
            callback = sinon.stub()
            callback.returns done()

            addTests raml, tests, hooks, callback, testFactory, false
          .catch (err) ->
            console.error err
            done(err)
        return

      after () ->
        tests = []

      it 'should run callback', () ->
        assert.ok callback.called

      it 'should add 1 test', () ->
        assert.lengthOf tests, 1

      it 'should set test.name', () ->
        assert.equal tests[0].name, 'GET /machines -> 200'

      it 'should setup test.request', () ->
        req = tests[0].request

        assert.equal req.path, '/machines'
        assert.deepEqual req.params, {}
        assert.deepEqual req.query, {}
        assert.deepEqual req.headers,
          'Abao-API-Key': 'abcdef'
        req.body.should.be.empty
        assert.equal req.method, 'GET'

      it 'should setup test.response', () ->
        res = tests[0].response

        assert.equal res.status, 200
        schema = res.schema
        assert.equal schema.items.properties.type.type, 'string'
        assert.equal schema.items.properties.name.type, 'string'
        assert.isNull res.headers
        assert.isNull res.body


    describe 'when endpoint has multiple methods', () ->

      describe 'when processed in order specified in RAML', () ->

        tests = []
        testFactory = new TestFactory()
        callback = undefined

        before (done) ->
          ramlFile = "#{RAML_DIR}/machines-1_get_1_post.raml"
          ramlParser.loadFile(ramlFile)
            .then (raml) ->
              callback = sinon.stub()
              callback.returns done()

              addTests raml, tests, hooks, callback, testFactory, false
            .catch (err) ->
              console.error err
              done(err)
          return

        after () ->
          tests = []

        it 'should run callback', () ->
          assert.ok callback.called

        it 'should add 2 tests', () ->
          assert.lengthOf tests, 2

        it 'should process GET request before POST request', () ->
          req = tests[0].request
          assert.equal req.method, 'GET'
          req = tests[1].request
          assert.equal req.method, 'POST'

        it 'should setup test.request of POST', () ->
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

        it 'should setup test.response of POST', () ->
          res = tests[1].response

          assert.equal res.status, 201
          schema = res.schema
          assert.equal schema.properties.type.type, 'string'
          assert.equal schema.properties.name.type, 'string'
          assert.isNull res.headers
          assert.isNull res.body


      describe 'when processed in order specified by "--sorted" option', () ->

        tests = []
        testFactory = new TestFactory()
        callback = undefined

        before (done) ->
          ramlFile = "#{RAML_DIR}/machines-1_get_1_post.raml"
          ramlParser.loadFile(ramlFile)
            .then (raml) ->
              callback = sinon.stub()
              callback.returns done()

              addTests raml, tests, hooks, null, callback, testFactory, true
            .catch (err) ->
              console.error err
              done(err)
          return

        after () ->
          tests = []

        it 'should run callback', () ->
          assert.ok callback.called

        it 'should add 2 tests', () ->
          assert.lengthOf tests, 2

        it 'should process GET request after POST request', () ->
          req = tests[0].request
          assert.equal req.method, 'POST'
          req = tests[1].request
          assert.equal req.method, 'GET'

        it 'should setup test.request of POST', () ->
          req = tests[0].request

          assert.equal req.path, '/machines'
          assert.deepEqual req.params, {}
          assert.deepEqual req.query, {}
          assert.deepEqual req.headers,
            'Content-Type': 'application/json'
          assert.deepEqual req.body,
            type: 'Kulu'
            name: 'Mike'
          assert.equal req.method, 'POST'

        it 'should setup test.response of POST', () ->
          res = tests[0].response

          assert.equal res.status, 201
          schema = res.schema
          assert.equal schema.properties.type.type, 'string'
          assert.equal schema.properties.name.type, 'string'
          assert.isNull res.headers
          assert.isNull res.body


    describe 'when RAML includes multiple referencing schemas', () ->

      tests = []
      testFactory = new TestFactory()
      callback = undefined

      before (done) ->
        ramlFile = "#{RAML_DIR}/machines-ref_other_schemas.raml"
        ramlParser.loadFile(ramlFile)
          .then (raml) ->
            callback = sinon.stub()
            callback.returns done()

            addTests raml, tests, hooks, callback, testFactory, false
          .catch (err) ->
            console.error err
            done(err)
        return

      after () ->
        tests = []

      it 'should run callback', () ->
        assert.ok callback.called

      it 'should add 1 test', () ->
        assert.lengthOf tests, 1

      it 'should set test.name', () ->
        assert.equal tests[0].name, 'GET /machines -> 200'

      it 'should setup test.request', () ->
        req = tests[0].request

        assert.equal req.path, '/machines'
        assert.deepEqual req.params, {}
        assert.deepEqual req.query, {}
        req.body.should.be.empty
        assert.equal req.method, 'GET'

      it 'should setup test.response', () ->
        res = tests[0].response

        assert.equal res.status, 200
        assert.equal res.schema?.properties?.chick?.type, 'string'
        assert.isNull res.headers
        assert.isNull res.body


    describe 'when RAML has inline and included schemas', () ->

      tests = []
      testFactory = new TestFactory()
      callback = undefined

      before (done) ->
        ramlFile = "#{RAML_DIR}/machines-inline_and_included_schemas.raml"
        ramlParser.loadFile(ramlFile)
          .then (raml) ->
            callback = sinon.stub()
            callback.returns done()

            addTests raml, tests, hooks, callback, testFactory, false
          .catch (err) ->
            console.error err
            done(err)
        return

      after () ->
        tests = []

      it 'should run callback', () ->
        assert.ok callback.called

      it 'should add 1 test', () ->
        assert.lengthOf tests, 1

      it 'should set test.name', () ->
        assert.equal tests[0].name, 'GET /machines -> 200'

      it 'should setup test.request', () ->
        req = tests[0].request

        assert.equal req.path, '/machines'
        assert.deepEqual req.params, {}
        assert.deepEqual req.query, {}
        req.body.should.be.empty
        assert.equal req.method, 'GET'

      it 'should setup test.response', () ->
        res = tests[0].response

        assert.equal res.status, 200
        assert.equal res.schema?.properties?.type['$ref'], 'type2'
        assert.isNull res.headers
        assert.isNull res.body


    describe 'when RAML contains three-levels endpoints', () ->

      tests = []
      testFactory = new TestFactory()
      callback = undefined

      before (done) ->
        ramlFile = "#{RAML_DIR}/machines-three_levels.raml"
        ramlParser.loadFile(ramlFile)
          .then (raml) ->
            callback = sinon.stub()
            callback.returns done()

            addTests raml, tests, hooks, callback, testFactory, false
          .catch (err) ->
            console.error err
            done(err)
        return

      after () ->
        tests = []

      it 'should run callback', () ->
        assert.ok callback.called

      it 'should add 3 tests', () ->
        assert.lengthOf tests, 3

      it 'should set test.name', () ->
        assert.equal tests[0].name, 'GET /machines -> 200'
        assert.equal tests[1].name, 'DELETE /machines/{machine_id} -> 204'
        assert.equal tests[2].name, 'GET /machines/{machine_id}/parts -> 200'

      it 'should set request.param of test 1', () ->
        test = tests[1]
        assert.deepEqual test.request.params,
          machine_id: '1'

      it 'should set request.param of test 2', () ->
        test = tests[2]
        assert.deepEqual test.request.params,
          machine_id: '1'


    describe 'when RAML has resource not defined method', () ->

      tests = []
      testFactory = new TestFactory()
      callback = undefined

      before (done) ->
        ramlFile = "#{RAML_DIR}/machines-no_method.raml"
        ramlParser.loadFile(ramlFile)
          .then (raml) ->
            callback = sinon.stub()
            callback.returns done()

            addTests raml, tests, hooks, callback, testFactory, false
          .catch (err) ->
            console.error err
            done(err)
        return

      after () ->
        tests = []

      it 'should run callback', () ->
        assert.ok callback.called

      it 'should add 1 test', () ->
        assert.lengthOf tests, 1

      it 'should set test.name', () ->
        assert.equal tests[0].name, 'GET /root/machines -> 200'


    describe 'when RAML has invalid request body example', () ->

      tests = []
      testFactory = new TestFactory()
      callback = undefined

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
          .then (raml) ->
            callback = sinon.stub()
            callback.returns done()

            sinon.stub console, 'warn'
            addTests raml, tests, hooks, callback, testFactory, false
          .catch (err) ->
            console.error err
            done(err)
        return

      after () ->
        tests = []
        console.warn.restore()

      it 'should run callback', () ->
        assert.ok callback.called

      it 'should give a warning', () ->
        assert.ok console.warn.called

      it 'should add 1 test', () ->
        assert.lengthOf tests, 1
        assert.equal tests[0].name, 'POST /machines -> 204'


    describe 'when RAML media type uses a JSON-suffixed vendor tree subtype', () ->

      tests = []
      testFactory = new TestFactory()
      callback = undefined

      before (done) ->
        ramlFile = "#{RAML_DIR}/music-vendor_content_type.raml"
        ramlParser.loadFile(ramlFile)
          .then (raml) ->
            callback = sinon.stub()
            callback.returns done()

            addTests raml, tests, hooks, callback, testFactory, false
          .catch (err) ->
            console.error err
            done(err)
        return

      after () ->
        tests = []

      it 'should run callback', () ->
        assert.ok callback.called

      it 'should add 1 test', () ->
        assert.lengthOf tests, 1

      it 'should setup test.request of PATCH', () ->
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

      it 'should setup test.response of PATCH', () ->
        res = tests[0].response

        assert.equal res.status, 200
        schema = res.schema
        assert.equal schema.properties.title.type, 'string'
        assert.equal schema.properties.artist.type, 'string'


    describe 'when there is required query parameter with example value', () ->

      tests = []
      testFactory = new TestFactory()
      callback = undefined

      before (done) ->
        ramlFile = "#{RAML_DIR}/machines-required_query_parameter.raml"
        ramlParser.loadFile(ramlFile)
          .then (raml) ->
            callback = sinon.stub()
            callback.returns done()

            addTests raml, tests, hooks, callback, testFactory, false
          .catch (err) ->
            console.error err
            done(err)
        return

      after () ->
        tests = []

      it 'should run callback', () ->
        assert.ok callback.called

      it 'should add 1 test', () ->
        assert.lengthOf tests, 1

      it 'should append query parameters with example value', () ->
        assert.equal tests[0].request.query['quux'], 'foo'


    describe 'when there is no required query parameter', () ->

      tests = []
      testFactory = new TestFactory()
      callback = undefined

      before (done) ->
        ramlFile = "#{RAML_DIR}/machines-non_required_query_parameter.raml"
        ramlParser.loadFile(ramlFile)
          .then (raml) ->
            callback = sinon.stub()
            callback.returns done()

            addTests raml, tests, hooks, callback, testFactory, false
          .catch (err) ->
            console.error err
            done(err)
        return

      after () ->
        tests = []

      it 'should run callback', () ->
        assert.ok callback.called

      it 'should add 1 test', () ->
        assert.lengthOf tests, 1

      it 'should not append query parameters', () ->
        assert.deepEqual tests[0].request.query, {}

