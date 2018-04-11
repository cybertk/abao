require 'coffee-errors'
chai = require 'chai'
chai.use require('sinon-chai')
{EventEmitter} = require 'events'
mute = require 'mute'
nock = require 'nock'
proxyquire = require 'proxyquire'
sinon = require 'sinon'

assert = chai.assert
expect = chai.expect
should = chai.should()

globStub = require 'glob'
pathStub = require 'path'
hooksStub = require '../../lib/hooks'

addHooks = proxyquire  '../../lib/add-hooks', {
  'glob': globStub,
  'path': pathStub
}

describe 'addHooks(hooks, pattern, callback)', () ->
  'use strict'

  callback = undefined
  globSyncSpy = undefined
  addHookSpy = undefined
  pathResolveSpy = undefined
  consoleErrorSpy = undefined
  transactions = {}

  describe 'with no pattern', () ->

    before () ->
      callback = sinon.spy()
      globSyncSpy = sinon.spy globStub, 'sync'

    it 'should return immediately', (done) ->
      addHooks hooksStub, '', callback
      globSyncSpy.should.not.have.been.called
      done()

    it 'should return successful continuation', () ->
      callback.should.have.been.calledOnce
      callback.should.have.been.calledWith(
        sinon.match.typeOf('null'))

    after () ->
      globStub.sync.restore()


  describe 'with pattern', () ->

    context 'not matching any files', () ->

      pattern = '/path/to/directory/without/hooks/*'

      beforeEach () ->
        callback = sinon.spy()
        addHookSpy = sinon.spy hooksStub, 'addHook'
        globSyncSpy = sinon.stub globStub, 'sync'
          .callsFake (pattern) ->
            []
        pathResolveSpy = sinon.spy pathStub, 'resolve'

      it 'should not return any file names', (done) ->
        mute (unmute) ->
          addHooks hooksStub, pattern, callback
          globSyncSpy.should.have.returned []
          unmute()
          done()

      it 'should not attempt to load files', (done) ->
        mute (unmute) ->
          addHooks hooksStub, pattern, callback
          pathResolveSpy.should.not.have.been.called
          unmute()
          done()

      it 'should propagate the error condition', (done) ->
        mute (unmute) ->
          addHooks hooksStub, pattern, callback
          callback.should.have.been.calledOnce
          detail = "no hook files found matching pattern '#{pattern}'"
          callback.should.have.been.calledWith(
            sinon.match.instanceOf(Error).and(
              sinon.match.has('message', detail)))
          unmute()
          done()

      afterEach () ->
        hooksStub.addHook.restore()
        globStub.sync.restore()
        pathStub.resolve.restore()


    context 'matching files', () ->

      pattern = './test/**/*_hooks.*'

      it 'should return file names', (done) ->
        mute (unmute) ->
          globSyncSpy = sinon.spy globStub, 'sync'
          addHooks hooksStub, pattern, callback
          globSyncSpy.should.have.been.called
          globStub.sync.restore()
          unmute()
          done()


      context 'when files are valid javascript/coffeescript', () ->

        beforeEach () ->
          callback = sinon.spy()
          globSyncSpy = sinon.spy globStub, 'sync'
          pathResolveSpy = sinon.spy pathStub, 'resolve'
          addHookSpy = sinon.spy hooksStub, 'addHook'

        it 'should load the files', (done) ->
          mute (unmute) ->
            addHooks hooksStub, pattern, callback
            pathResolveSpy.should.have.been.called
            unmute()
            done()

        it 'should attach the hooks', (done) ->
          mute (unmute) ->
            addHooks hooksStub, pattern, callback
            addHookSpy.should.have.been.called
            unmute()
            done()

        it 'should return successful continuation', (done) ->
          mute (unmute) ->
            addHooks hooksStub, pattern, callback
            callback.should.have.been.calledOnce
            callback.should.have.been.calledWith(
              sinon.match.typeOf('null'))
            unmute()
            done()

        afterEach () ->
          globStub.sync.restore()
          pathStub.resolve.restore()
          hooksStub.addHook.restore()


      context 'when error occurs reading the hook files', () ->

        addHookSpy = undefined
        consoleErrorSpy = undefined

        beforeEach () ->
          callback = sinon.spy()
          pathResolveSpy = sinon.stub pathStub, 'resolve'
            .callsFake (path, rel) ->
              throw new Error 'resolve'
          consoleErrorSpy = sinon.spy console, 'error'
          globSyncSpy = sinon.stub globStub, 'sync'
            .callsFake (pattern) ->
              ['invalid.xml', 'unexist.md']
          addHookSpy = sinon.spy hooksStub, 'addHook'

        it 'should log an error', (done) ->
          mute (unmute) ->
            addHooks hooksStub, pattern, callback
            consoleErrorSpy.should.have.been.called
            unmute()
            done()

        it 'should not attach the hooks', (done) ->
          mute (unmute) ->
            addHooks hooksStub, pattern, callback
            addHookSpy.should.not.have.been.called
            unmute()
            done()

        it 'should propagate the error condition', (done) ->
          mute (unmute) ->
            addHooks hooksStub, pattern, callback
            callback.should.have.been.calledOnce
            callback.should.have.been.calledWith(
              sinon.match.instanceOf(Error).and(
                sinon.match.has('message', 'resolve')))
            unmute()
            done()

        afterEach () ->
          pathStub.resolve.restore()
          console.error.restore()
          globStub.sync.restore()
          hooksStub.addHook.restore()

