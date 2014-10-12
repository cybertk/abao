options =
  hookfiles:
    alias: 'f'
    description: 'Specifes a pattern to match files with before/after hooks for running tests'
    default: null

  names:
    alias: 'n'
    description: 'Only list names of requests (for use in a hookfile). No requests are made.'
    default: false

  reporter:
    alias: "r"
    description: "Output additional report format. This option can be used multiple times to add multiple reporters. Options: junit, nyan, dot, markdown, html, apiary.\n"
    default: "spec"

  header:
    alias: "h"
    description: "Extra header to include in every request. This option can be used multiple times to add multiple headers.\n"
    default: []

  'hooks-only':
    alias: "H"
    description: "Run test only if defined either before or after hooks"
    default: false

  user:
    alias: "u"
    description: "Basic Auth credentials in the form username:password.\n"
    default: null

  method:
    alias: "m"
    description: "Restrict tests to a particular HTTP method (GET, PUT, POST, DELETE, PATCH). This option can be used multiple times to allow multiple methods.\n"
    default: []

  help:
    description: "Show usage information.\n"

  version:
    description: "Show version number.\n"

module.exports = options
