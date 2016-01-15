## Abao
> RAML testing tool

[![Stories in Ready](https://badge.waffle.io/cybertk/abao.svg?label=ready&title=Ready)](http://waffle.io/cybertk/abao)
[![Build Status](http://img.shields.io/travis/cybertk/abao.svg?style=flat)](https://travis-ci.org/cybertk/abao)
[![Dependency Status](https://david-dm.org/cybertk/abao.svg)](https://david-dm.org/cybertk/abao)
[![devDependency Status](https://david-dm.org/cybertk/abao/dev-status.svg)](https://david-dm.org/cybertk/abao#info=devDependencies)
[![Coverage Status](https://img.shields.io/coveralls/cybertk/abao.svg)](https://coveralls.io/r/cybertk/abao)

**Abao** is a command-line tool for testing API documentation written in [RAML][] format against its backend implementation. With **Abao** you can easily plug your API documentation into the Continous Integration system like Travis CI or Jenkins and have API documentation up-to-date, all the time. Abao uses the [Mocha][] for judging if a particular API response is valid or if is not.

## Features

- Verify that each endpoint defined in RAML exists in service
- Verify that each endpoint url params defined in RAML are supported in service
- Verify that each endpoint request HTTP headers defined in RAML are supported in service
- Verify that each endpoint request body defined in RAML is supported in service - verify by validating the JSON schema
- Verify that each endpoint response HTTP headers defined in RAML are supported in service
- Verify that each endpoint response body defined in RAML is supported in service - verify by validating the JSON schema
- Verify test data defined in files which support defining multiple test cases - verify based on [test case definition](#test-case-definition)

## Installation

Install stable version

    npm install -g frontnode/abao

## Get Started Testing Your API

    abao api.raml http://127.0.0.1:9091 eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6Imp5OXFwbDRqbmoifQ.eyJ1aWQiOiI1NGExNDYxZWI4MTM3NDgwMDQ4YjQ1NjciLCJzY29wZXMiOltdLCJhcHAiOiI1NTQ5YWI2ZGI4MTM3NDdhMTQ4YjQ1NmEifQ.SdnfjnBANrZaqMZhjAjwf90fHpREPGCVR88ichhB0XY

## Test part of your APIs

    abao api.raml http://127.0.0.1:9091 eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6Imp5OXFwbDRqbmoifQ.eyJ1aWQiOiI1NGExNDYxZWI4MTM3NDgwMDQ4YjQ1NjciLCJzY29wZXMiOltdLCJhcHAiOiI1NTQ5YWI2ZGI4MTM3NDdhMTQ4YjQ1NmEifQ.SdnfjnBANrZaqMZhjAjwf90fHpREPGCVR88ichhB0XY -g /cap

## Writing testable RAML

**Abao** validates the response from server against jsonschema defines in [RAML][], so there must be **schema** section in defined in [RAML][].

### Test Case definition

//TODO
Every test case is defined based on configuration (JSON format)

## Hooks

**Abao** can be configured to use hookfiles to do basic setup/teardown between each validation (specified with the --hookfiles flag). Hookfiles can be in javascript or coffeescript, and must import the hook methods.

**NOTE**: The hookfile's extension must be `.coffee` if it's written in coffeescript.

Requests are identified by their name, which is derived from the structure of the RAML. You can print a list of the generated names with --names.

### Example

Get Names:

```bash
$ abao single-get.raml --names
GET /machines -> 200
```

Write a hookfile in **JavaScript**:

```js
var hooks = require('hooks');

hooks.before('GET /machines -> 200', function(test, done) {
    test.request.query = {color: 'red'};
    done();
});

hooks.after('GET /machines -> 200', function(test, done) {
    machine = test.response.body[0];
    console.log(machine.name);
    done();
});
```

Write a hookfile in **CoffeeScript**:

```coffee
{before, after} = require 'hooks'

before 'GET /machines -> 200', (test, done) ->
  test.request.query =
    color: 'red'
  done()

after 'GET /machines -> 200', (test, done) ->
  machine = test.response.body[0]
  console.log machine.name
  done()
```

Run validation:

```bash
$ abao single-get.raml http://api.example.com --hookfiles=*_hooks.*
```

**Abao** also supports callbacks before and after all tests:

```coffee
{beforeAll, afterAll} = require 'hooks'

beforeAll (done) ->
  # do setup
  done()

afterAll (done) ->
  # do teardown
  done()
```

If `beforeAll`, `afterAll`, `before` and `after` are called multiple times, the callbacks are executed serially in the order they were called.

### test.request

- `server` - Server address, provided from CLI.
- `path` - API endpoint path, parsed from RAML.
- `method` - http method, parsed from RAML.
- `params` - URI parameters, parsed from RAML `uriParameters` section, default to `{}`.
- `query` - object containing querystring values to be appended to the `path`, default to `{}`.
- `headers` - http headers, parsed from RAML `headers` section, default to `{}`.
- `body` - entity body for PATCH, POST and PUT requests. Must be a JSON-serializable object. Parsed from RAML `example` section, default to `{}`

### test.response

- `status` - Expected http response code, parsed from RAML.
- `schema` - Expected schema of http response, parsed from RAML `schema` section.
- `headers` - Headers object got from testing server, default to `{}`
- `body` - http json body got from testing server. default to `null`

## Command Line Options

```
Usage: 
  abao <path to raml> <api_endpoint> <access_token> [OPTIONS]

Example: 
  abao ./api.raml http://api.example.com eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IjR6Z3lreWU1Z2IifQ.eyJ1aWQiOiI1NGNiNjM0YWJhMWI4MjkzMzQ4YjQ1NjciLCJzY29wZXMiOltdLCJhcHAiOiI1NjU3OWU0ZjhmNWU4OGFlNDk4YjQ2ZjkifQ.o_wkfghQcX8rTyBr8Eu76rKiiBpQ_bCoUdD0saCAYpQ

Options:
  --hookfiles, -f   Specifies a pattern to match files with before/after hooks
                    for running tests                            [default: null]
  --schemas, -s     Specifies a pattern to match files schemas that will be
                    loaded so they can be used as JSON refs      [default: null]
  --names, -n       Only list names of requests (for use in a hookfile). No
                    requests are made.                          [default: false]
  --reporter, -r    Specify the reporter to use                [default: "spec"]
  --header, -h      Extra header to include in every request. The header must
                    be in KEY:VALUE format, e.g. '-h Accept:application/json'.
                    This option can be used multiple times to add multiple
                    headers                                                     
  --hooks-only, -H  Run test only if defined either before or after hooks       
  --read-only, -R   Run test only for GET methods                               
  --grep, -g        only run tests for path matching <regular expression>       
  --invert, -i      inverts --grep matches                                      
  --timeout, -t     set test-case timeout in milliseconds        [default: 2000]
  --reporters       Display available reporters                                 
  --help            Show usage information                                      
  --version         Show version number
```


## Run Tests

    $ npm test

## Contribution

Any contribution is more than welcome!

[RAML]: http://raml.org
[mocha]: http://mochajs.org

