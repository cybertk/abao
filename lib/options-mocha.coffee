###*
# @file Command line options (Mocha-related)
###

module.exports =
  grep:
    alias: 'g'
    description: 'Only run tests matching <pattern>'
    type: 'string'

  invert:
    alias: 'i'
    description: 'Invert --grep matches'
    type: 'boolean'

  reporter:
    alias: 'R'
    description: 'Specify reporter to use'
    type: 'string'
    default: 'spec'

  reporters:
    description: 'Display available reporters and exit'
    type: 'boolean'

  timeout:
    alias: 't'
    description: 'Set test case timeout in milliseconds'
    type: 'number'
    default: 2000

