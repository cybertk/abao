###*
# @file Command line interface
###

require 'coffee-script/register'

child_process = require 'child_process'
path = require 'path'
_ = require 'lodash'
yargs = require 'yargs'

Abao = require './abao'
pkg = require '../package'

mochaOptionNames = [
  'grep',
  'invert'
  'reporter',
  'reporters',
  'timeout'
]

EXIT_SUCCESS = 0
EXIT_FAILURE = 1

showReporters = () ->
  'use strict'
  mochaDir = path.dirname require.resolve('mocha')
  mochaPkg = require 'mocha/package'
  executable = path.join mochaDir, mochaPkg.bin._mocha
  executable = path.normalize executable
  stdoutBuff = child_process.execFileSync executable, ['--reporters']
  stdout = stdoutBuff.toString()
  stdout = stdout.slice 0, stdout.length - 1   # Remove last newline
  console.log stdout
  return

parseArgs = (argv) ->
  'use strict'
  prog = path.basename pkg.bin
  return yargs(argv)
    .usage("Usage:\n  #{prog} </path/to/raml> [OPTIONS]" +
      "\n\nExample:\n  #{prog} api.raml --server http://api.example.com")
    .options(Abao.options)
    .group(mochaOptionNames, 'Options passed to Mocha:')
    .implies('template', 'generate-hooks')
    .check((argv) ->
      if argv.reporters == true
        showReporters()
        process.exit EXIT_SUCCESS

      # Ensure single positional argument present
      if argv._.length < 1
        throw new Error "#{prog}: must specify path to RAML file"
      else if argv._.length > 1
        throw new Error "#{prog}: accepts single positional command-line argument"

      return true
    )
    .wrap(80)
    .help('help', 'Show usage information and exit')
    .version('version', 'Show version number and exit', pkg.version)
    .epilog("Website:\n  #{pkg.homepage}")
    .argv

##
## Main
##
main = (argv) ->
  'use strict'
  parsedArgs = parseArgs argv

  ## TODO(plroebuck): Do all configuration in one place...
  aliases = Object.keys(Abao.options).map (key) -> Abao.options[key].alias
              .filter (val) -> val != undefined
  alreadyHandled = [
    'reporters',
    'help',
    'version'
  ]

  configuration =
    ramlPath: parsedArgs._[0],
    options: _.omit parsedArgs, ['_', '$0', aliases..., alreadyHandled...]

  mochaOptions = _.pick configuration.options, mochaOptionNames
  configuration.options = _.omit configuration.options, mochaOptionNames
  configuration.options.mocha = mochaOptions

  abao = new Abao configuration
  abao.run (error, nfailures) ->
    if error
      process.exitCode = EXIT_FAILURE
      if error.message
        console.error error.message
      if error.stack
        console.error error.stack

    if nfailures > 0
      process.exitCode = EXIT_FAILURE

    process.exit()
  return # NOTREACHED


module.exports =
  main: main

