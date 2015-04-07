{assert} = require('chai')
{exec} = require('child_process')
express = require 'express'


CMD_PREFIX = ''
PORT = '3333'

stderr = ''
stdout = ''
report = ''
exitStatus = null

recievedRequest = {}

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
        assert.equal report.tests[0].fullTitle, 'GET /machines -> 200 Validate response code and body'

    describe "when executing the command and raml includes other ramls", () ->
      before (done) ->
        cmd = "./bin/abao ./test/fixtures/include_other_raml.raml http://localhost:#{PORT}"

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
        assert.include stdout, '1 passing'

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
        assert.include stdout, '1 passing'

    describe "when adding additional headers with -h", ->

      recievedRequest = {}

      before (done) ->
        cmd = "./bin/abao ./test/fixtures/single-get.raml http://localhost:#{PORT} -h Accept:application/json"

        app = express()

        app.get '/machines', (req, res) ->
          recievedRequest = req
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

      it 'should have an additional header in the request', () ->
        assert.equal recievedRequest.headers.accept, 'application/json'

      it 'exit status should be 0', () ->
        assert.equal exitStatus, 0

      it 'should print count of tests will run', ->
        assert.include stdout, '1 passing'


    describe "when printing test cases with -n", ->
      before (done) ->
        cmd = "./bin/abao ./test/fixtures/single-get.raml -n"

        execCommand cmd, done

      it 'exit status should be 0', () ->
        assert.equal exitStatus, 0

      it 'should print names', () ->
        assert.include stdout, 'GET /machines -> 200'

      it 'should not run tests', () ->
        assert.notInclude stdout, '0 passing'


    describe 'when loading hooks with --hookfiles', () ->

      recievedRequest = {}

      before (done) ->
        cmd = "./bin/abao ./test/fixtures/single-get.raml http://localhost:#{PORT} --hookfiles=./test/fixtures/*_hooks.*"

        app = express()

        app.get '/machines', (req, res) ->
          recievedRequest = req
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

      it 'should modify the transaction with hooks', () ->
        assert.equal recievedRequest.headers['header'], '123232323'
        assert.equal recievedRequest.query['key'], 'value'

      it 'should print message to stdout and stderr', ->
        assert.include stdout, 'before-hook-GET-machines'
        assert.include stderr, 'after-hook-GET-machines'


    describe 'when run with --hooks-only', () ->
      before (done) ->
        cmd = "./bin/abao ./test/fixtures/single-get.raml http://localhost:#{PORT} --hooks-only"

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

      it 'should not run test without hooks', ->
        assert.include stdout, '1 pending'

    describe 'when run with --timeout', () ->
      cost = ''

      before (done) ->
        cmd = "./bin/abao ./test/fixtures/single-get.raml http://localhost:#{PORT} --timeout 100"

        app = express()

        t0 = ''
        app.get '/machines', (req, res) ->
          t0 = new Date

        server = app.listen PORT, () ->
          execCommand cmd, () ->
            cost = new Date - t0
            server.close()

        server.on 'close', done

      it 'exit status should be 1', () ->
        assert.equal exitStatus, 1

      it 'should exit before timeout', ->
        assert.ok cost < 200

      it 'should not run test without hooks', ->
        assert.include stdout, '0 passing'

    describe 'when run with --reporters', () ->
      reporters = ''

      before (done) ->
        execCommand './node_modules/mocha/bin/mocha --reporters', ->
          reporters = stdout
          execCommand './bin/abao --reporters', done

      it 'exit status should be 0', () ->
        assert.equal exitStatus, 0

      it 'should print reporters same as `mocha --reporters`', ->
        assert.equal stdout, reporters
