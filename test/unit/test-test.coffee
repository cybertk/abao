{assert} = require 'chai'
sinon = require 'sinon'
proxyquire = require('proxyquire').noCallThru()

requestStub = sinon.stub()
requestStub.restore = () ->
  this.callsArgWith(1, null, {statusCode: 200}, '')


Test = proxyquire '../../src/test', {
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
        test.request.body = 'http-body'
        test.response.status = 201
        test.response.schema = """
          type: 'string'
          name: 'string'
        """

        machine =
          type: 'foo'
          name: 'bar'

        requestStub.callsArgWith(1, null, {statusCode: 201}, JSON.stringify(machine))
        test.run done

      after ->
        requestStub.restore()

      it 'should call #request', ->
        assert.ok requestStub.calledOnce
        # assert.ok requestStub.calledWith({url: 'http://abao.io/machines'})
        assert.ok requestStub.calledWith(
          url: 'http://abao.io/machines'
          method: 'POST'
          headers:
            key: 'value'
          body: 'http-body'
        ), requestStub.printf('%C')

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
        assert.deepEqual response.schema, """
          type: 'string'
          name: 'string'
        """

        # changed properties
        # assert.equal response.headers, 201
        assert.deepEqual response.body, machine


  describe '#assertResponse', ->

    errorStub = ''
    responseStub = ''
    bodyStub = ''

    test = new Test()
    test.response.status = 201
    test.response.schema = JSON.stringify
      $schema: 'http://json-schema.org/draft-04/schema#'
      type: 'object'
      properties:
        type:
          type: 'string'
        name:
          type: 'string'

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
