{assert} = require('chai')
{exec} = require('child_process')
express = require 'express'


CMD_PREFIX = ''
PORT = '3333'

stderr = ''
stdout = ''
report = ''
exitStatus = null

execCommand = (cmd, callback) ->
  stderr = ''
  stdout = ''
  report = ''
  exitStatus = null

  cli = exec CMD_PREFIX + cmd, (error, out, err) ->
    stdout = out
    stderr = err
    try
      report = JSON.parse out

    if error
      exitStatus = error.code

  exitEventName = if process.version.split('.')[1] is '6' then 'exit' else 'close'

  cli.on exitEventName, (code) ->
    exitStatus = code if exitStatus == null and code != undefined
    callback()

describe "Command line interface", ->

  describe "When raml file not found", (done) ->
    before (done) ->
      cmd = "./bin/abao ./test/fixtures/nonexistent_path.raml http://localhost:#{PORT}"

      execCommand cmd, done

    it 'should exit with status 1', ->
      assert.equal exitStatus, 1

    it 'should print error message to stderr', ->
      assert.include stderr, 'Error: ENOENT, open'


  describe "Arguments with existing raml and responding server", () ->

    describe "when executing the command and the server is responding as specified in the raml", () ->
      before (done) ->
        cmd = "./bin/abao -r json ./test/fixtures/single-get.raml http://localhost:#{PORT}"

        app = express()

        app.get '/machines', (req, res) ->
          res.setHeader 'Content-Type', 'application/json'
          machine =
            type: 'bulldozer'
            name: 'willy'
          response = [machine]
          res.status(200).send response

        server = app.listen PORT, () ->
          execCommand cmd, () ->
            server.close()

        server.on 'close', done

      it 'exit status should be 0', () ->
        assert.equal exitStatus, 0

      it 'should print count of tests will run', ->
        assert.equal 1, report.tests.length
        assert.equal 1, report.passes.length

      it 'should print correct title for response', ->
        assert.equal report.tests[0].fullTitle, '/machines GET response 200'


  describe 'when called with arguments', ->

    describe "when using additional reporters with -r", ->

      before (done) ->
        cmd = "./bin/abao -r spec ./test/fixtures/single-get.raml http://localhost:#{PORT}"

        app = express()

        app.get '/machines', (req, res) ->
          res.setHeader 'Content-Type', 'application/json'
          machine =
            type: 'bulldozer'
            name: 'willy'
          response = [machine]
          res.status(200).send response

        server = app.listen PORT, () ->
          execCommand cmd, () ->
            server.close()

        server.on 'close', done

      it 'should print using the new reporter', ->
        assert.include stdout, 'passing'
