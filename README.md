## Abao

> RAML testing tool

[![Build Status](http://img.shields.io/travis/cybertk/abao.svg?style=flat)](https://travis-ci.org/cybertk/abao)
[![Dependency Status](https://david-dm.org/cybertk/abao.png)](https://david-dm.org/cybertk/abao)
[![devDependency Status](https://david-dm.org/cybertk/abao/dev-status.svg)](https://david-dm.org/cybertk/abao#info=devDependencies)
[![Coverage Status](https://coveralls.io/repos/lizhexia/abao/badge.png?branch=master)](https://coveralls.io/r/lizhexia/abao?branch=master)

**Abao** is a command-line tool for testing API documentation written in [RAML][] format against its backend implementation. With **Abao** you can easily plug your API documentation into the Continous Integration system like Travis CI or Jenkins and have API documentation up-to-date, all the time. Abao uses the [Mocha][] for judging if a particular API response is valid or if is not.

## Features

- Verify that each endpoint defined in RAML exists in service
- Verify that each endpoint url params defined in RAML are supported in service
- Verify that each endpoint request HTTP headers defined in RAML are supported in service
- Verify that each endpoint request body defined in RAML is supported in service - verify by validating the JSON schema
- Verify that each endpoint response HTTP headers defined in RAML are supported in service
- Verify that each endpoint response body defined in RAML is supported in service - verify by validating the JSON schema

## Installation

[Node.js][] and [NPM][] is required.

    $ npm install abao

[Node.js]: https://npmjs.org/
[NPM]: https://npmjs.org/

## Get Started Testing Your API

$ abao api.raml http://api.example.com

## Writing testable blueprints

Abao validates the response from server against jsonschema defines in [RAML][], so there must be **schema** section in defined in [RAML][].

### Hooks

### Example

## Command Line Options



## Contribution

## Run Tests

    $ npm test

Any contribution is more then welcome!

[RAML]: http://raml.org
[mocha]: http://visionmedia.github.io/mocha/
