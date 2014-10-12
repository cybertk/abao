require 'coffee-errors'
{assert} = require 'chai'
{EventEmitter} = require 'events'
nock = require 'nock'
proxyquire = require 'proxyquire'
sinon = require 'sinon'

globStub = require 'glob'
pathStub = require 'path'
hooksStub = require '../../src/hooks'

addHooks = proxyquire  '../../src/add-hooks', {
  'glob': globStub,
  'path': pathStub
}

describe 'addHooks(hooks, pattern, callback)', () ->

  transactions = {}

  describe 'with no pattern', () ->

    before () ->
      sinon.spy globStub, 'sync'

    after () ->
      globStub.sync.restore()

    it 'should return immediately', ->
      addHooks(hooksStub, '')
      assert.ok globStub.sync.notCalled

  describe 'with valid pattern', () ->

    pattern = './**/*_hooks.*'

    it 'should return files', ->
      sinon.spy globStub, 'sync'
      addHooks(hooksStub, pattern)
      assert.ok globStub.sync.called
      globStub.sync.restore()

    describe 'when files are valid js/coffeescript', () ->

      beforeEach () ->
        sinon.spy globStub, 'sync'
        sinon.spy pathStub, 'resolve'
        sinon.spy hooksStub, 'addHook'

      afterEach () ->
        globStub.sync.restore()
        pathStub.resolve.restore()
        hooksStub.addHook.restore()

      it 'should load the files', () ->
        addHooks(hooksStub, pattern)
        assert.ok pathStub.resolve.called

      it 'should attach the hooks', () ->
        addHooks(hooksStub, pattern)
        assert.ok hooksStub.addHook.called


    describe 'when there is an error reading the hook files', () ->

      beforeEach () ->
        sinon.stub pathStub, 'resolve', (path, rel) ->
          throw new Error()
        sinon.spy console, 'error'
        sinon.stub globStub, 'sync', (pattern) ->
          ['invalid.xml', 'unexist.md']
        sinon.spy hooksStub, 'addHook'

      afterEach () ->
        pathStub.resolve.restore()
        console.error.restore()
        globStub.sync.restore()
        hooksStub.addHook.restore()

      it 'should log an warning', () ->
        addHooks(hooksStub, pattern)
        assert.ok console.error.called

      it 'should not attach the hooks', () ->
        addHooks(hooksStub, pattern)
        assert.ok hooksStub.addHook.notCalled
