chai = require 'chai'
sinon = require 'sinon'
sinonChai = require 'sinon-chai'
_ = require 'underscore'
proxyquire = require('proxyquire').noCallThru()

assert = chai.assert
should = chai.should()
chai.use(sinonChai)

requestStub = sinon.stub()
requestStub.restore = () ->
  'use strict'
  this.callsArgWith 1, null, {statusCode: 200}, ''

TestFactory = proxyquire '../../lib/test', {
  'request': requestStub
}

ABAO_IO_SERVER = 'http://abao.io'


describe 'TestFactory', () ->
  'use strict'

  describe 'constructor', () ->

    globStub = {}
    globStub.sync = sinon.spy (location) ->
      return [location]

    fsStub = {}
    fsStub.readFileSync = sinon.spy () ->
      return '{ "text": "example" }'

    tv4Stub = {}
    tv4Stub.addSchema = sinon.spy()

    TestTestFactory = proxyquire '../../lib/test', {
      'fs': fsStub,
      'glob': globStub,
      'tv4': tv4Stub
    }

    it 'test TestFactory without parameter', () ->
      new TestTestFactory ''
      assert.isFalse globStub.sync.called
      assert.isFalse fsStub.readFileSync.called
      assert.isFalse tv4Stub.addSchema.called

    it 'test TestFactory with name 1', () ->
      new TestTestFactory 'thisisaword'
      assert.isTrue globStub.sync.calledWith 'thisisaword'
      assert.isTrue fsStub.readFileSync.calledOnce
      assert.isTrue fsStub.readFileSync.calledWith 'thisisaword', 'utf8'
      assert.isTrue tv4Stub.addSchema.calledWith JSON.parse '{ "text": "example" }'

    it 'test TestFactory with name 2', () ->
      new TestTestFactory 'thisIsAnotherWord'
      assert.isTrue globStub.sync.calledWith 'thisIsAnotherWord'
      assert.isTrue fsStub.readFileSync.calledTwice
      assert.isTrue fsStub.readFileSync.calledWith 'thisIsAnotherWord', 'utf8'
      assert.isTrue tv4Stub.addSchema.calledWith JSON.parse '{ "text": "example" }'


describe 'Test', () ->
  'use strict'

  describe '#run', () ->

    describe 'of simple test', () ->

      testFact = undefined
      test = undefined
      machine = undefined
      contentTestCalled = undefined
      callback = undefined

      before (done) ->
        testFact = new TestFactory()
        test = testFact.create()
        contentTestCalled = false
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
        test.request.body =
          body: 'value'
        test.response.status = 201
        test.response.schema = [
          type: 'object'
          properties:
            type: 'string'
            name: 'string'
        ]

        machine =
          type: 'foo'
          name: 'bar'

        test.contentTest = (response, body, callback) ->
          contentTestCalled = true
          try
            assert.equal response.status, 201
            assert.deepEqual machine, JSON.parse body
          catch err
            return callback err
          return callback null

        requestStub.callsArgWith 1, null, {statusCode: 201}, JSON.stringify machine
        callback = sinon.stub()
        callback.returns done()

        test.run callback

      after () ->
        requestStub.restore()

      it 'should call #request', () ->
        requestStub.should.be.calledWith
          url: "#{ABAO_IO_SERVER}/machines"
          method: 'POST'
          headers:
            key: 'value'
          qs:
            q: 'value'
          body: JSON.stringify
            body: 'value'

      it 'should not modify @name', () ->
        assert.equal test.name, 'POST /machines -> 201'

      it 'should not modify @request', () ->
        request = test.request
        assert.equal request.server, "#{ABAO_IO_SERVER}"
        assert.equal request.path, '/machines'
        assert.equal request.method, 'POST'
        assert.deepEqual request.params, {param: 'value'}
        assert.deepEqual request.query, {q: 'value'}
        assert.deepEqual request.headers, {key: 'value'}

      it 'should update @response', () ->
        response = test.response
        # Unchanged properties
        assert.equal response.status, 201
        # Changed properties
        assert.deepEqual response.body, machine

      it 'should call contentTest', () ->
        assert.isTrue contentTestCalled

      it 'should return successful continuation', () ->
        callback.should.have.been.calledOnce
        callback.should.have.been.calledWith(
          sinon.match.typeOf('null'))


    describe 'of test that contains params', () ->

      test = undefined
      machine = undefined
      callback = undefined

      before (done) ->
        testFact = new TestFactory()
        test = testFact.create()
        test.name = 'PUT /machines/{machine_id} -> 200'
        test.request.server = "#{ABAO_IO_SERVER}"
        test.request.path = '/machines/{machine_id}'
        test.request.method = 'PUT'
        test.request.params =
          machine_id: '1'
        test.request.query =
          q: 'value'
        test.request.headers =
          key: 'value'
        test.request.body =
          body: 'value'
        test.response.status = 200
        test.response.schema = [
          type: 'object'
          properties:
            type: 'string'
            name: 'string'
        ]

        machine =
          type: 'foo'
          name: 'bar'

        requestStub.callsArgWith 1, null, {statusCode: 200}, JSON.stringify machine
        callback = sinon.stub()
        callback.returns done()

        test.run callback

      after () ->
        requestStub.restore()

      it 'should call #request', () ->
        requestStub.should.be.calledWith
          url: "#{ABAO_IO_SERVER}/machines/1"
          method: 'PUT'
          headers:
            key: 'value'
          qs:
            q: 'value'
          body: JSON.stringify
            body: 'value'

      it 'should not modify @name', () ->
        assert.equal test.name, 'PUT /machines/{machine_id} -> 200'

      it 'should not modify @request', () ->
        request = test.request
        assert.equal request.server, "#{ABAO_IO_SERVER}"
        assert.equal request.path, '/machines/{machine_id}'
        assert.equal request.method, 'PUT'
        assert.deepEqual request.params, {machine_id: '1'}
        assert.deepEqual request.query, {q: 'value'}
        assert.deepEqual request.headers, {key: 'value'}

      it 'should update @response', () ->
        response = test.response
        # Unchanged properties
        assert.equal response.status, 200
        assert.deepEqual response.body, machine

      it 'should return successful continuation', () ->
        callback.should.have.been.calledOnce
        callback.should.have.been.calledWith(
          sinon.match.typeOf('null'))


  describe '#url', () ->

    describe 'when called with path that does not contain param', () ->

      testFact = new TestFactory()
      test = testFact.create()
      test.request.path = '/machines'

      it 'should return origin path', () ->
        assert.equal test.url(), '/machines'


    describe 'when called with path that contains param', () ->

      testFact = new TestFactory()
      test = testFact.create()
      test.request.path = '/machines/{machine_id}/parts/{part_id}'
      test.request.params =
        machine_id: 'tianmao'
        part_id: 2

      it 'should replace all params', () ->
        assert.equal test.url(), '/machines/tianmao/parts/2'

      it 'should not touch origin request.path', () ->
        assert.equal test.request.path, '/machines/{machine_id}/parts/{part_id}'


  describe '#assertResponse', () ->

    responseStub = undefined
    bodyStub = undefined

    testFact = new TestFactory()
    test = testFact.create()
    test.response.status = 201
    test.response.schema = {
      $schema: 'http://json-schema.org/draft-04/schema#'
      type: 'object'
      properties:
        type:
          type: 'string'
        name:
          type: 'string'
    }

    describe 'when given valid response', () ->

      it 'should pass all asserts', () ->
        responseStub =
          statusCode: 201
        bodyStub = JSON.stringify
          type: 'foo'
          name: 'bar'
        fn = _.partial test.assertResponse, responseStub, bodyStub
        assert.doesNotThrow fn


    describe 'when given invalid response', () ->

      describe 'when response body is null', () ->

        it 'should throw AssertionError', () ->
          responseStub =
            statusCode: 201
          bodyStub = null
          fn = _.partial test.assertResponse, responseStub, bodyStub
          assert.throw fn, chai.AssertionError


      describe 'when response body is invalid JSON', () ->

        it 'should throw AssertionError', () ->
          responseStub =
            statusCode: 201
          bodyStub = 'Im invalid'
          fn = _.partial test.assertResponse, responseStub, bodyStub
          assert.throw fn, chai.AssertionError

