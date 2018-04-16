chai = require 'chai'
_ = require 'lodash'
proxyquire = require('proxyquire').noCallThru()
sinon = require 'sinon'
sinonChai = require 'sinon-chai'

assert = chai.assert
expect = chai.expect
should = chai.should()
chai.use sinonChai

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

    describe 'when basic test', () ->

      test = undefined
      machine = undefined
      callback = undefined
      contentTestCalled = undefined

      before (done) ->
        factory = new TestFactory()
        testname = 'POST /machines -> 201'
        test = factory.create testname
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

        contentTestCalled = false
        test.contentTest = (response, body, callback) ->
          assert.equal typeof response, 'object'
          assert.equal typeof body, 'string'
          assert.equal typeof callback, 'function'
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

      it 'should make HTTP request', () ->
        options =
          url: "#{ABAO_IO_SERVER}/machines"
          method: 'POST'
          headers:
            key: 'value'
          qs:
            q: 'value'
          body: JSON.stringify
            body: 'value'
        requestStub.should.be.calledWith options

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


    describe 'when test contains params', () ->

      test = undefined
      machine = undefined
      callback = undefined

      before (done) ->
        factory = new TestFactory()
        testname = 'PUT /machines/{machine_id} -> 200'
        test = factory.create testname
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

      it 'should make HTTP request', () ->
        options =
          url: "#{ABAO_IO_SERVER}/machines/1"
          method: 'PUT'
          headers:
            key: 'value'
          qs:
            q: 'value'
          body: JSON.stringify
            body: 'value'
        requestStub.should.be.calledWith options

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


    describe 'when HTTP request fails due to Error', () ->

      factory = undefined
      test = undefined
      err = undefined
      callback = undefined

      before () ->
        requestStub.reset()
        factory = new TestFactory()
        testname = 'POST /machines -> 201'
        test = factory.create testname
        test.request.server = "#{ABAO_IO_SERVER}"
        test.request.method = 'POST'
        test.request.path = '/machines'
        test.request.body = 'dontcare'

      context 'while attempting to connect', () ->

        before (done) ->
          err = new Error 'ETIMEDOUT'
          err.code = 'ETIMEDOUT'
          err.connect = true

          requestStub.callsArgWith 1, err
          callback = sinon.spy()
          callback.returns done()

        after () ->
          requestStub.restore()

        it 'should propagate the error condition', () ->
          test.run callback
          detail = 'timed out attempting to establish connection'
          callback.should.have.been.calledOnce
          error = callback.args[0][0]
          expect(error).to.exist
          expect(error).to.be.instanceof(Error)
          expect(error).to.have.property('code', 'ETIMEDOUT')
          expect(error).to.have.property('connect', true)
          expect(error).to.have.property('message', detail)


      context 'while awaiting server response', () ->

        before (done) ->
          err = new Error 'ETIMEDOUT'
          err.code = 'ETIMEDOUT'
          err.connect = false

          requestStub.callsArgWith 1, err
          callback = sinon.spy()
          callback.returns done()

        after () ->
          requestStub.restore()

        it 'should propagate the error condition', () ->
          test.run callback
          detail = 'timed out awaiting server response'
          callback.should.have.been.calledOnce
          error = callback.args[0][0]
          expect(error).to.exist
          expect(error).to.be.instanceof(Error)
          expect(error).to.have.property('code', 'ETIMEDOUT')
          expect(error).to.have.property('message', detail)


      context 'when server stopped sending response data', () ->

        before (done) ->
          err = new Error 'ESOCKETTIMEDOUT'
          err.code = 'ESOCKETTIMEDOUT'
          err.connect = false

          requestStub.callsArgWith 1, err
          callback = sinon.spy()
          callback.returns done()

        after () ->
          requestStub.restore()

        it 'should propagate the error condition', () ->
          test.run callback
          detail = 'timed out when server stopped sending response data'
          callback.should.have.been.calledOnce
          error = callback.args[0][0]
          expect(error).to.exist
          expect(error).to.be.instanceof(Error)
          expect(error).to.have.property('code', 'ESOCKETTIMEDOUT')
          expect(error).to.have.property('message', detail)


      context 'when connection reset by server', () ->

        before (done) ->
          err = new Error 'ECONNRESET'
          err.code = 'ECONNRESET'

          requestStub.callsArgWith 1, err
          callback = sinon.spy()
          callback.returns done()

        after () ->
          requestStub.restore()

        it 'should propagate the error condition', () ->
          test.run callback
          detail = 'connection reset by server'
          callback.should.have.been.calledOnce
          error = callback.args[0][0]
          expect(error).to.exist
          expect(error).to.be.instanceof(Error)
          expect(error).to.have.property('code', 'ECONNRESET')
          expect(error).to.have.property('message', detail)


  describe '#url', () ->

    describe 'when called with path that does not contain param', () ->

      factory = new TestFactory()
      test = factory.create()
      test.request.path = '/machines'

      it 'should return origin path', () ->
        assert.equal test.url(), '/machines'


    describe 'when called with path that contains param', () ->

      factory = new TestFactory()
      test = factory.create()
      test.request.path = '/machines/{machine_id}/parts/{part_id}'
      test.request.params =
        machine_id: 'tianmao'
        part_id: 2

      it 'should replace all params', () ->
        assert.equal test.url(), '/machines/tianmao/parts/2'

      it 'should not touch origin request.path', () ->
        assert.equal test.request.path, '/machines/{machine_id}/parts/{part_id}'


  describe '#validateResponse', () ->

    responseStub = undefined
    bodyStub = undefined

    factory = new TestFactory()
    test = factory.create()
    test.response.status = 201
    test.response.schema =
      $schema: 'http://json-schema.org/draft-04/schema#'
      type: 'object'
      properties:
        type:
          type: 'string'
        name:
          type: 'string'

    describe 'when given valid response', () ->

      before () ->
        responseStub =
          statusCode: 201
        bodyStub = JSON.stringify
          type: 'foo'
          name: 'bar'

      it 'should not throw', () ->
        fn = _.partial test.validateResponse, responseStub, bodyStub
        assert.doesNotThrow fn


    describe 'when given invalid response', () ->

      describe 'when response body is empty', () ->

        before () ->
          responseStub =
            statusCode: 201
          bodyStub = ''

        it 'should throw Error', () ->
          fn = _.partial test.validateResponse, responseStub, bodyStub
          assert.throws fn, Error, /response body is empty/


      describe 'when response body is invalid JSON', () ->

        before () ->
          responseStub =
            statusCode: 201
          bodyStub = 'Im invalid'

        it 'should throw SyntaxError', () ->
          fn = _.partial test.validateResponse, responseStub, bodyStub
          assert.throws fn, SyntaxError, /Unexpected token/


      describe 'when response body is null', () ->

        before () ->
          responseStub =
            statusCode: 201
          bodyStub = null

        it 'should throw Error', () ->
          fn = _.partial test.validateResponse, responseStub, bodyStub
          assert.throws fn, Error, /schema validation failed/

