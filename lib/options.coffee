options =
  server:
    description: 'Specifies the API endpoint to use'
    default: '<RAML-specified "baseUri" property>'

  hookfiles:
    alias: 'f'
    description: 'Specifies a pattern to match files with before/after hooks for running tests'
    default: null

  schemas:
    alias: 's'
    description: 'Specifies a pattern to match schema files to be loaded for use as JSON refs'
    default: null

  reporter:
    alias: 'r'
    description: 'Specify the reporter to use'
    default: 'spec'

  header:
    alias: 'h'
    description: 'Extra header to include in every request. The header must be in KEY:VALUE format, e.g. "-h Accept:application/json".\nReuse to add multiple headers'

  'hooks-only':
    alias: 'H'
    description: 'Run test only if defined either before or after hooks'

  grep:
    alias: 'g'
    description: 'Only run tests matching <pattern>'

  invert:
    alias: 'i'
    description: 'Inverts --grep matches'

  timeout:
    alias: 't'
    description: 'Set test-case timeout in milliseconds'
    default: 2000

  names:
    alias: 'n'
    description: 'List names of requests and exit'
    default: false

  reporters:
    description: 'Display available reporters and exit'

  help:
    description: 'Show usage information and exit'

  version:
    description: 'Show version number and exit'

  'generate-hooks':
    description: "Generate skeleton hooks file"

module.exports = options

