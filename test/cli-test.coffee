{assert} = require 'chai'
{exec} = require 'child_process'
express = require 'express'

pjson = require '../package.json'

HOSTNAME = 'localhost'
PORT = 3333
SERVER = "http://#{HOSTNAME}:#{PORT}"

TEMPLATE_DIR = './templates'
DFLT_TEMPLATE_FILE = "#{TEMPLATE_DIR}/hooks.js"
FIXTURE_DIR = './test/fixtures'
RAML_DIR = "#{FIXTURE_DIR}"
HOOK_DIR = "#{FIXTURE_DIR}"
SCHEMA_DIR = "#{FIXTURE_DIR}/schemas"

CMD_PREFIX = ''
ABAO_BIN = './bin/abao'
MOCHA_BIN = './node_modules/mocha/bin/mocha'

stderr = ''
stdout = ''
report = ''
exitStatus = null

receivedRequest = {}

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

  cli.on 'close', (code) ->
    exitStatus = code if exitStatus == null and code != undefined
    callback()

describe 'Command line interface', ->

  describe 'when run with "one and done" options', (done) ->

    describe 'when RAML argument unnecessary', () ->

      describe 'when invoked with "--reporters" option', () ->
        reporters = ''

        before (done) ->
          execCommand "#{MOCHA_BIN} --reporters", ->
            reporters = stdout
            execCommand "#{ABAO_BIN} --reporters", done
        it 'exit status should be 0', () ->
          assert.equal exitStatus, 0

        it 'should print same output as `mocha --reporters`', ->
          assert.equal stdout, reporters


      describe 'when invoked with "--version" option', () ->
        before (done) ->
          cmd = "#{ABAO_BIN} --version"

          execCommand cmd, done

        it 'should exit with status 0', ->
          assert.equal exitStatus, 0

        it 'should print version number to stdout', ->
          assert.equal stdout.trim(), pjson.version


      describe 'when invoked with "--help" option', () ->
        before (done) ->
          cmd = "#{ABAO_BIN} --help"

          execCommand cmd, done

        it 'should exit with status 0', ->
          assert.equal exitStatus, 0

        it 'should print usage to stdout', ->
          assert.equal stdout.split('\n')[0], 'Usage:'

    describe 'when RAML argument required', () ->

      describe 'when invoked with "--names" option', ->
        before (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --names"

          execCommand cmd, done

        it 'exit status should be 0', () ->
          assert.equal exitStatus, 0

        it 'should print names', () ->
          assert.include stdout, 'GET /machines -> 200'

        it 'should not run tests', () ->
          assert.notInclude stdout, '0 passing'


      describe 'when invoked with "--generate-hooks" option', () ->
        describe 'by itself', () ->
          before (done) ->
            ramlFile = "#{RAML_DIR}/single-get.raml"
            cmd = "#{ABAO_BIN} #{ramlFile} --generate-hooks"

            execCommand cmd, done

          it 'exit status should be 0', () ->
            assert.equal exitStatus, 0

          it 'should print skeleton hookfile', ->
            assert.include stdout, '// ABAO hooks file'

          it 'should not run tests', () ->
            assert.notInclude stdout, '0 passing'


        describe 'with "--template" option', () ->
          before (done) ->
            templateFile = "#{TEMPLATE_DIR}/hookfile.js"
            ramlFile = "#{RAML_DIR}/single-get.raml"
            cmd = "#{ABAO_BIN} #{ramlFile} --generate-hooks --template #{templateFile}"

            execCommand cmd, done

          it 'exit status should be 0', () ->
            assert.equal exitStatus, 0

          it 'should print skeleton hookfile', ->
            assert.include stdout, '// ABAO hooks file'

          it 'should not run tests', () ->
            assert.notInclude stdout, '0 passing'

      describe 'when invoked with "--template" but without "--generate-hooks" option', () ->
        before (done) ->
          templateFile = "#{TEMPLATE_DIR}/hookfile.js"
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --template #{templateFile}"

          execCommand cmd, done

        it 'exit status should be 1', () ->
          assert.equal exitStatus, 1

        it 'should print error message to stderr', ->
          assert.include stderr, 'Implications failed:'
          assert.include stderr, 'template -> generate-hooks'


  describe 'when RAML file not found', (done) ->
    before (done) ->
      ramlFile = "#{RAML_DIR}/nonexistent_path.raml"
      cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER}"

      execCommand cmd, done

    it 'should exit with status 1', ->
      assert.equal exitStatus, 1

    it 'should print error message to stderr', ->
      # See https://travis-ci.org/cybertk/abao/jobs/76656192#L479
      # iojs behaviour is different from nodejs
      assert.include stderr, 'Error: ENOENT'


  describe 'arguments with existing RAML and responding server', () ->
    describe 'when invoked without "--server" option', () ->
      describe 'when RAML file does not specify "baseUri"', () ->
        before (done) ->
          ramlFile = "#{RAML_DIR}/no-base-uri.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --reporter json"

          execCommand cmd, done

        it 'should exit with status 1', ->
          assert.equal exitStatus, 1

        it 'should print error message to stderr', ->
          assert.include stderr, 'no API endpoint specified'

      describe 'when RAML file does specify "baseUri"', () ->

        before (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --reporter json"

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

        it 'should print count of tests run', ->
          assert.equal 1, report.tests.length
          assert.equal 1, report.passes.length

        it 'should print correct title for response', ->
          assert.equal report.tests[0].fullTitle, 'GET /machines -> 200 Validate response code and body'

    describe 'when executing the command and the server is responding as specified in the RAML', () ->
      before (done) ->
        ramlFile = "#{RAML_DIR}/single-get.raml"
        cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --reporter json"

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

      it 'should print count of tests run', ->
        assert.equal 1, report.tests.length
        assert.equal 1, report.passes.length

      it 'should print correct title for response', ->
        assert.equal report.tests[0].fullTitle, 'GET /machines -> 200 Validate response code and body'

    describe 'when executing the command and RAML includes other RAML files', () ->
      before (done) ->
        ramlFile = "#{RAML_DIR}/include_other_raml.raml"
        cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER}"

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

      it 'should print count of tests run', ->
        assert.include stdout, '1 passing'

    describe 'when called with arguments', ->

      describe 'when invoked with "--reporter" option', ->
        before (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --reporter spec"

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

        it 'should print using the specified reporter', ->
          assert.include stdout, '1 passing'

      describe 'when invoked with "--header" option', ->

        receivedRequest = {}

        before (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --header Accept:application/json"

          app = express()

          app.get '/machines', (req, res) ->
            receivedRequest = req
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
          assert.equal receivedRequest.headers.accept, 'application/json'

        it 'exit status should be 0', () ->
          assert.equal exitStatus, 0

        it 'should print count of tests run', ->
          assert.include stdout, '1 passing'


      describe 'when invoked with "--hookfiles" option', () ->

        receivedRequest = {}

        before (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --hookfiles=#{HOOK_DIR}/*_hooks.*"

          app = express()

          app.get '/machines', (req, res) ->
            receivedRequest = req
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
          assert.equal receivedRequest.headers['header'], '123232323'
          assert.equal receivedRequest.query['key'], 'value'

        it 'should print message to stdout and stderr', ->
          assert.include stdout, 'before-hook-GET-machines'
          assert.include stderr, 'after-hook-GET-machines'


      describe 'when invoked with "--hooks-only" option', () ->
        before (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --hooks-only"

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

      describe 'when invoked with "--timeout" option', () ->
        cost = ''

        before (done) ->
          ramlFile = "#{RAML_DIR}/single-get.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --timeout 100"

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

      describe 'when invoked with "--schema" option', () ->

        before (done) ->
          ramlFile = "#{RAML_DIR}/with-json-refs.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --schemas=#{SCHEMA_DIR}/*.json --server #{SERVER}"
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

      describe 'when invoked with "--schema" option and expecting error', () ->
        before (done) ->
          ramlFile = "#{RAML_DIR}/with-json-refs.raml"
          cmd = "#{ABAO_BIN} #{ramlFile} --server #{SERVER} --schemas=#{SCHEMA_DIR}/*.json"

          app = express()

          app.get '/machines', (req, res) ->
            res.setHeader 'Content-Type', 'application/json'
            machine =
              typO: 'bulldozer'
              name: 'willy'
            response = [machine]
            res.status(200).send response

          server = app.listen PORT, () ->
            execCommand cmd, () ->
              server.close()

          server.on 'close', done

        it 'exit status should be 1', () ->
          assert.equal exitStatus, 1
