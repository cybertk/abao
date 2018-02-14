## Abao
> RAML testing tool

[![Gitter](https://badges.gitter.im/cybertk/abao.svg)](https://gitter.im/cybertk/abao?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
[![Stories in Ready](https://badge.waffle.io/cybertk/abao.svg?label=ready&title=Ready)](https://waffle.io/cybertk/abao)
[![Build Status](https://img.shields.io/travis/cybertk/abao.svg?style=flat)](https://travis-ci.org/cybertk/abao)
[![Dependency Status](https://david-dm.org/cybertk/abao.svg)](https://david-dm.org/cybertk/abao)
[![devDependency Status](https://david-dm.org/cybertk/abao/dev-status.svg)](https://david-dm.org/cybertk/abao#info=devDependencies)
[![Coverage Status](https://img.shields.io/coveralls/cybertk/abao.svg)](https://coveralls.io/r/cybertk/abao)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/388/badge)](https://bestpractices.coreinfrastructure.org/projects/388) 

**Abao** is a command-line tool for testing API documentation written in
[RAML][] format against its back-end implementation. With **Abao**, you can
easily plug your API documentation into a Continuous Integration (CI) system
(e.g., [Travis][], [Jenkins][]) and have API documentation up-to-date, all
the time. **Abao** uses [Mocha][] for judging if a particular API response
is valid or not.

## Features

- Verify that each endpoint defined in RAML exists in service
- Verify that URL params for each endpoint defined in RAML are supported in service
- Verify that the required query parameters defined in RAML are supported in service
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

**Abao** can generate a hookfile to help validate more than just the
response code for each path.

```bash
$ ABAO_HOME="/path/to/node_modules/abao"
$ TEMPLATE="${ABAO_HOME}/templates/hookfile.js"
$ abao single-get.raml --generate-hooks --template="${TEMPLATE}" > test_machines_hooks.js

```

Then edit the *JavaScript* hookfile `test_machines_hooks.js` created in the
previous step to add request parameters and response validation logic.

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

Also you can specify what test **Abao** should skip:

```js
var hooks = require('hooks');

hooks.skip('DELETE /machines/{machineId} -> 204');
```

**Abao** also supports callbacks before and after all tests:

```coffee
{beforeEach, afterEach} = require 'hooks'

beforeEach (test, done) ->
  # do setup
  done()

afterEach (test, done) ->
  # do teardown
  done()
```

If `beforeEach`, `afterEach`, `before` and `after` are called multiple times,
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
- `query` - Object containing querystring values to be appended to the `path`,parsed from RAML `queryParameters` section [default: `{}`].
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
  --server          Specify the API endpoint to use. The RAML-specified baseUri
                    value will be used if not provided                  [string]
  --hookfiles, -f   Specify a pattern to match files with before/after hooks for
                    running tests                                       [string]
  --schemas, -s     Specify a pattern to match schema files to be loaded for use
                    as JSON refs                                        [string]
  --reporter, -r    Specify the reporter to use       [string] [default: "spec"]
  --header, -h      Add header to include in each request. The header must be in
                    KEY:VALUE format, e.g. "-h Accept:application/json".
                    Reuse to add multiple headers                       [string]
  --hooks-only, -H  Run test only if defined either before or after hooks
                                                                       [boolean]
  --grep, -g        Only run tests matching <pattern>                   [string]
  --invert, -i      Invert --grep matches                              [boolean]
  --sorted          Sorts requests in a sensible way so that objects are not
                    modified before they are created. Order: CONNECT, OPTIONS,
                    POST, GET, HEAD, PUT, PATCH, DELETE, TRACE.        [boolean]
  --timeout, -t     Set test-case timeout in milliseconds
                                                        [number] [default: 2000]
  --template        Specify the template file to use for generating hooks
                                                                        [string]
  --names, -n       List names of requests and exit                    [boolean]
  --generate-hooks  Output hooks generated from template file and exit [boolean]
  --reporters       Display available reporters and exit               [boolean]
  --help            Show usage information and exit                    [boolean]
  --version         Show version number and exit                       [boolean]
```

## Run Tests

```bash
$ npm test
```

## Contribution

**Abao** is always looking for new ideas to make the codebase useful.
If you think of something that would make life easier, please submit an issue.

[RAML]: https://raml.org/
[Mocha]: https://mochajs.org/
[JSONSchema]: http://json-schema.org/
[Travis]: https://travis-ci.org/
[Jenkins]: https://jenkins-ci.org/
[baseUri]: https://github.com/raml-org/raml-spec/blob/master/raml-0.8.md#base-uri-and-baseuriparameters

