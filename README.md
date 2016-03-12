## Abao
> RAML testing tool

[![Stories in Ready](https://badge.waffle.io/cybertk/abao.svg?label=ready&title=Ready)](http://waffle.io/cybertk/abao)
[![Build Status](http://img.shields.io/travis/cybertk/abao.svg?style=flat)](https://travis-ci.org/cybertk/abao)
[![Dependency Status](https://david-dm.org/cybertk/abao.svg)](https://david-dm.org/cybertk/abao)
[![devDependency Status](https://david-dm.org/cybertk/abao/dev-status.svg)](https://david-dm.org/cybertk/abao#info=devDependencies)
[![Coverage Status](https://img.shields.io/coveralls/cybertk/abao.svg)](https://coveralls.io/r/cybertk/abao)

**Abao** is a command-line tool for testing API documentation written in
[RAML][] format against its back-end implementation. With **Abao**, you can
easily plug your API documentation into a Continuous Integration (CI) system
(e.g., [Travis][], [Jenkins][]) and have API documentation up-to-date, all
the time. **Abao** uses [Mocha][] for judging if a particular API response
is valid or not.

## Features

- Verify that each endpoint defined in RAML exists in service
- Verify that URL params for each endpoint defined in RAML are supported in service 
- Verify that HTTP request headers for each endpoint defined in RAML are supported in service
- Verify that HTTP request body for each endpoint defined in RAML is supported in service, via [JSONSchema][] validation
- Verify that HTTP response headers for each endpoint defined in RAML are supported in service
- Verify that HTTP response body for each endpoint defined in RAML is supported in service, via [JSONSchema][] validation

## Installation

Install stable version

```bash
$ npm install -g abao
```

Install latest development version in GitHub branch

```bash
$ npm install -g github:cybertk/abao
```

Un*x users will likely need to run these commands using `sudo`.

## Get Started Testing Your API

For general usage, an API endpoint (i.e., web service to be tested) **must**
be specified; this can be done implicitly or explicitly, with the latter
having priority. If the RAML file to be tested provides a [baseUri][] property,
the API endpoint is implicitly set to that value.

```bash
$ abao api.raml
```

To explicitly specify the API endpoint, use the `--server` argument.

```bash
$ abao api.raml --server http://localhost:8080
```

## Writing testable RAML

**Abao** validates the HTTP response body against `schema` defined in [RAML][].
**No response body will be returned if the corresponding [RAML][] `schema` is missing.**
However, the response status code can **always** be verified, regardless.

## Hooks

**Abao** can be configured to use hookfiles to do basic setup/teardown between
each validation (specified with the `--hookfiles` flag). Hookfiles can be
written in either JavaScript or CoffeeScript, and must import the hook methods.

**NOTE**: CoffeeScript files **must** use file extension `.coffee`.

Requests are identified by their name, which is derived from the structure of
the RAML. You can print a list of the generated names with the `--names` flag.

### Example

The RAML file used in the examples below can be found [here](../master/test/fixtures/single-get.raml).

Get Names:

```bash
$ abao single-get.raml --names
GET /machines -> 200
```

Write a hookfile in *JavaScript* named `test_machines_hooks.js`:

```js
var hooks = require('hooks'),
    assert = require('chai').assert;

hooks.before('GET /machines -> 200', function (test, done) {
    test.request.query = {
      color: 'red'
    };
    done();
});

hooks.after('GET /machines -> 200', function (test, done) {
    machine = test.response.body[0];
    console.log(machine.name);
    done();
});
```

Alternately, write the same hookfile in *CoffeeScript* named
`test_machines_hooks.coffee`:

```coffee
{before, after} = require 'hooks'
{assert} = require 'chai'

before 'GET /machines -> 200', (test, done) ->
  test.request.query =
    color: 'red'
  done()

after 'GET /machines -> 200', (test, done) ->
  machine = test.response.body[0]
  console.log machine.name
  done()
```

Run validation with *JavaScript* hookfile (from above):

```bash
$ abao single-get.raml --hookfiles=test_machines_hooks.js
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

If `beforeAll`, `afterAll`, `before` and `after` are called multiple times,
the callbacks are executed serially in the order they were called.

**Abao** provides hook to allow the content of the response to be checked
within the test:

```coffee
{test} = require 'hooks'
{assert} = require 'chai'

test 'GET /machines -> 200', (response, body, done) ->
    assert.deepEqual(JSON.parse(body), ["machine1", "machine2"])
    assert.equal(headers['content-type'], 'application/json; charset=utf-8')
    return done()
```

### test.request

- `server` - Server address, provided from command line.
- `path` - API endpoint path, parsed from RAML.
- `method` - HTTP method, parsed from RAML request method (e.g., `get`).
- `params` - URI parameters, parsed from RAML request `uriParameters` [default: `{}`].
- `query` - Object containing querystring values to be appended to the `path` [default: `{}`].
- `headers` - HTTP headers, parsed from RAML `headers` [default: `{}`].
- `body` - Entity body for POST, PUT, and PATCH requests. Must be a JSON-serializable object. Parsed from RAML `example` [default: `{}`].

### test.response

- `status` - Expected HTTP response code, parsed from RAML response status.
- `schema` - Expected schema of HTTP response body, parsed from RAML response `schema`.
- `headers` - Object containing HTTP response headers from server [default: `{}`].
- `body` - HTTP response body (JSON-format) from server [default: `null`].

## Command Line Options

```
Usage:
  abao </path/to/raml> [OPTIONS]

Example:
  abao api.raml --server http://api.example.com

Options:
  --server          Specifies the API endpoint to use. The RAML-specified
                    baseUri value will be used if none provided [default: null]
  --hookfiles, -f   Specifes a pattern to match files with before/after hooks
                    for running tests                           [default: null]
  --schemas, -s     Specifies a pattern to match schema files to be loaded for
                    use as JSON refs                            [default: null]
  --names, -n       Only list names of requests (for use in a hookfile). No
                    requests are made.                          [default: false]
  --reporter, -r    Specify the reporter to use                [default: 'spec']
  --header, -h      Extra header to include in every request. The header must
                    be in KEY:VALUE format (e.g., '-h Accept:application/json').
                    This option can be used multiple times to add multiple
                    headers                                                     
  --hooks-only, -H  Run test only if defined either before or after hooks
  --grep, -g        Only run tests matching <pattern>
  --invert, -i      Inverts `--grep` matches
  --timeout, -t     Set test-case timeout in milliseconds       [default: 2000]
  --reporters       Display available reporters
  --help            Show usage information
  --version         Show version number
```

## Run Tests

```bash
$ npm test
```

## Contribution

**Abao** is always looking for new ideas to make the codebase useful.
If you think of something that would make life easier, please submit an issue.

[RAML]: http://raml.org/
[Mocha]: http://mochajs.org/
[JSONSchema]: http://json-schema.org/
[Travis]: https://travis-ci.org/
[Jenkins]: https://jenkins-ci.org/
[baseUri]: https://github.com/raml-org/raml-spec/blob/master/raml-0.8.md#base-uri-and-baseuriparameters

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/cybertk/abao/trend.png)](https://bitdeli.com/free 'Bitdeli Badge')

