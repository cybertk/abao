options =
  server:
    description: 'Specify API endpoint to use. The RAML-specified baseUri value will be used if not provided'
    type: 'string'

  hookfiles:
    alias: 'f'
    description: 'Specify pattern to match files with before/after hooks for running tests'
    type: 'string'

  schemas:
    alias: 's'
    description: 'Specify pattern to match schema files to be loaded for use as JSON refs'
    type: 'string'

  'load-file-refs':
    description: 'For schema\'s containing $ref\'s which target the local filesystem, ' +
      'automatically expand those $ref\'s relative to the CWD of abao'
    type: 'boolean'

  reporter:
    alias: 'r'
    description: 'Specify reporter to use'
    type: 'string'
    default: 'spec'

  header:
    alias: 'h'
    description: 'Add header to include in each request. Header must be in KEY:VALUE format ' +
      '(e.g., "-h Accept:application/json").\nReuse option to add multiple headers'
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

  template:
    description: 'Specify template file to use for generating hooks'
    type: 'string'
    normalize: true

  names:
    alias: 'n'
    description: 'List names of requests and exit'
    type: 'boolean'

  'generate-hooks':
    description: 'Output hooks generated from template file and exit'
    type: 'boolean'

  reporters:
    description: 'Display available reporters and exit'
    type: 'boolean'

module.exports = options
