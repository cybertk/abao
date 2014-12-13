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
    description: "Extra header to include in every request. The header must be in KEY:VALUE format, e.g. '-h Accept:application/json'.\nThis option can be used multiple times to add multiple headers.\n"

  'hooks-only':
    alias: "H"
    description: "Run test only if defined either before or after hooks"

  grep:
    alias: "g"
    description: "only run tests matching <pattern>"

  invert:
    alias: "i"
    description: "inverts --grep matches"

  timeout:
    alias: "t"
    description: "set test-case timeout in milliseconds"
    default: 2000

  help:
    description: "Show usage information.\n"

  version:
    description: "Show version number.\n"

module.exports = options
