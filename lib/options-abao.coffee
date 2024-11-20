###*
# @file Command line options (Abao-related)
###

module.exports =
  'generate-hooks':
    description: 'Output hooks generated from template file and exit'
    type: 'boolean'

  header:
    alias: 'h'
    description: 'Add header to include in each request. Header must be ' +
                 'in KEY:VALUE format (e.g., "-h Accept:application/json").' +
                 '\nReuse option to add multiple headers'
    type: 'string'

  hookfiles:
    alias: 'f'
    description: 'Specify pattern to match files with before/after hooks ' +
                 'for running tests'
    type: 'string'

  'hooks-only':
    alias: 'H'
    description: 'Run test only if defined either before or after hooks'
    type: 'boolean'

  names:
    alias: 'n'
    description: 'List names of requests and exit'
    type: 'boolean'

  schemas:
    description: 'Specify pattern to match schema files to be loaded for ' +
                 'use as JSON $refs'
    type: 'string'

  server:
    description: 'Specify API endpoint to use. The RAML-specified baseUri ' +
                 'value will be used if not provided'
    type: 'string'

  sorted:
    description: 'Sorts requests in a sensible way so that objects are not ' +
                 'modified before they are created.\nOrder: ' +
                 'CONNECT, OPTIONS, POST, GET, HEAD, PUT, PATCH, DELETE, TRACE.'
    type: 'boolean'

  template:
    description: 'Specify template file to use for generating hooks'
    type: 'string'
    normalize: true

