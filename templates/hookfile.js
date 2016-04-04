//
// ABAO hooks file {{! Mustache template }}
// Generated from RAML specification
//   RAML: "{{ramlFile}}"
//   Date: "{{timestamp}}"
// <https://github.com/cybertk/abao>
//

var
  hooks = require('hooks'),
  assert = require('chai').assert;

//
// Setup/Teardown
//

hooks.beforeAll(function (done) {
  done();
});

hooks.afterAll(function (done) {
  done();
});


//
// Hooks
//

{{#hooks}}
//-----------------------------------------------------------------------------
hooks.before('{{{name}}}', function (test, done) {
  {{#comment}}
  // Modify 'test.request' properties here to modify the inbound request
  {{/comment}}
  done();
});

hooks.after('{{{name}}}', function (test, done) {
  {{#comment}}
  // Assert against 'test.response' properties here to verify expected results
  {{/comment}}
  done();
});

{{/hooks}}

