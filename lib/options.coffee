options =
  server:
    description: 'Specify the API endpoint to use. The RAML-specified baseUri value will be used if not provided'
    type: 'string'

  hookfiles:
    alias: 'f'
    description: 'Specify a pattern to match files with before/after hooks for running tests'
    type: 'string'

  schemas:
    alias: 's'
    description: 'Specify a pattern to match schema files to be loaded for use as JSON refs'
    type: 'string'

  reporter:
    alias: 'r'
    description: 'Specify the reporter to use'
    type: 'string'
    default: 'spec'

  header:
    alias: 'h'
    description: 'Add header to include in each request. The header must be in KEY:VALUE format, e.g. "-h Accept:application/json".\nReuse to add multiple headers'
    type: 'string'

  'hooks-only':
    alias: 'H'
    description: 'Run test only if defined either before or after hooks'
    type: 'boolean'

  grep:
    alias: 'g'
    description: 'Only run tests matching <pattern>'
    type: 'string'

  invert:
    alias: 'i'
    description: 'Invert --grep matches'
    type: 'boolean'

  timeout:
    alias: 't'
    description: 'Set test-case timeout in milliseconds'
    type: 'number'
    default: 2000

  names:
    alias: 'n'
    description: 'List names of requests and exit'
    type: 'boolean'

  reporters:
    description: 'Display available reporters and exit'
    type: 'boolean'

module.exports = options

