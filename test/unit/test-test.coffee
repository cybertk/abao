chai = require 'chai'
sinon = require 'sinon'
sinonChai = require 'sinon-chai'
_ = require 'underscore'
proxyquire = require('proxyquire').noCallThru()

assert = chai.assert
should = chai.should()
chai.use(sinonChai);

requestStub = sinon.stub()
requestStub.restore = () ->
  this.callsArgWith(1, null, {statusCode: 200}, '')


Test = proxyquire '../../lib/test', {
  'request': requestStub
}


describe 'Test', ->

  describe '#run', ->

    describe 'of simple test', ->

      test = ''
      machine = ''

      before (done) ->

        test = new Test()
        test.name = 'POST /machines -> 201'
        test.request.server = 'http://abao.io'
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
        test.response.schema = [{ type: 'object', properties: { type: 'string', name: 'string'}}]

        machine =
          type: 'foo'
          name: 'bar'

        requestStub.callsArgWith(1, null, {statusCode: 201}, JSON.stringify(machine))
        test.run done

      after ->
        requestStub.restore()

      it 'should call #request', ->
        requestStub.should.be.calledWith
          url: 'http://abao.io/machines'
          method: 'POST'
          headers:
            key: 'value'
          qs:
            q: 'value'
          body: JSON.stringify
            body: 'value'

      it 'should not modify @name', ->
        assert.equal test.name, 'POST /machines -> 201'

      it 'should not modify @request', ->
        request = test.request
        assert.equal request.server, 'http://abao.io'
        assert.equal request.path, '/machines'
        assert.equal request.method, 'POST'
        assert.deepEqual request.params, {param: 'value'}
        assert.deepEqual request.query, {q: 'value'}
        assert.deepEqual request.headers, {key: 'value'}

      it 'should update @response', ->
        response = test.response
        # Unchanged properties
        assert.equal response.status, 201

        # changed properties
        # assert.equal response.headers, 201
        assert.deepEqual response.body, machine


    describe 'of test contains params', ->

      test = ''
      machine = ''

      before (done) ->

        test = new Test()
        test.name = 'PUT /machines/{machine_id} -> 200'
        test.request.server = 'http://abao.io'
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
        test.response.schema = [{ type: 'object', properties: { type: 'string', name: 'string'}}]

        machine =
          type: 'foo'
          name: 'bar'

        requestStub.callsArgWith(1, null, {statusCode: 200}, JSON.stringify(machine))
        test.run done

      after ->
        requestStub.restore()

      it 'should call #request', ->
        requestStub.should.be.calledWith
          url: 'http://abao.io/machines/1'
          method: 'PUT'
          headers:
            key: 'value'
          qs:
            q: 'value'
          body: JSON.stringify
            body: 'value'

      it 'should not modify @name', ->
        assert.equal test.name, 'PUT /machines/{machine_id} -> 200'

      it 'should not modify @request', ->
        request = test.request
        assert.equal request.server, 'http://abao.io'
        assert.equal request.path, '/machines/{machine_id}'
        assert.equal request.method, 'PUT'
        assert.deepEqual request.params, {machine_id: '1'}
        assert.deepEqual request.query, {q: 'value'}
        assert.deepEqual request.headers, {key: 'value'}

      it 'should update @response', ->
        response = test.response
        # Unchanged properties
        assert.equal response.status, 200
        assert.deepEqual response.body, machine


  describe '#url', ->

    describe 'when call with path does not contain param', ->
      test = new Test()
      test.request.path = '/machines'

      it 'should return origin path', ->
        assert.equal test.url(), '/machines'

    describe 'when call with path contains param', ->
      test = new Test()
      test.request.path = '/machines/{machine_id}/parts/{part_id}'
      test.request.params =
        machine_id: 'tianmao'
        part_id: 2

      it 'should replace all params', ->
        assert.equal test.url(), '/machines/tianmao/parts/2'

      it 'should not touch origin request.path', ->
        assert.equal test.request.path, '/machines/{machine_id}/parts/{part_id}'


  describe '#assertResponse', ->

    errorStub = ''
    responseStub = ''
    bodyStub = ''

    test = new Test()
    test.response.status = 201
    test.response.schema = {
      $schema: 'http://json-schema.org/draft-04/schema#'
      type: 'object'
      properties:
        type:
          type: 'string'
        name:
          type: 'string'}

    describe 'when against valid response', ->

      it 'should should pass all asserts', ->

        errorStub = null
        responseStub =
          statusCode : 201
        bodyStub = JSON.stringify
          type: 'foo'
          name: 'bar'
        # assert.doesNotThrow
        test.assertResponse(errorStub, responseStub, bodyStub)

    describe 'when response body is null', ->

      it 'should throw AssertionError', ->

        errorStub = null
        responseStub =
          statusCode : 201
        bodyStub = null
        fn = _.partial test.assertResponse, errorStub, responseStub, bodyStub
        assert.throw fn, chai.AssertionError

    describe 'when response body is invalid json', ->

      it 'should throw AssertionError', ->

        errorStub = null
        responseStub =
          statusCode : 201
        bodyStub = 'Im invalid'
        fn = _.partial test.assertResponse, errorStub, responseStub, bodyStub
        assert.throw fn, chai.AssertionError
