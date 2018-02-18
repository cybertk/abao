###*
# @file Command line interface
###

require 'coffee-script/register'

path = require 'path'
yargs = require 'yargs'
Abao = require '../lib/abao'
pkg = require '../package'

EXIT_SUCCESS = 0
EXIT_FAILURE = 1

showReporters = () ->
  # Copied from node_modules/mocha/_mocha
  console.log()
  console.log '    dot - dot matrix'
  console.log '    doc - html documentation'
  console.log '    spec - hierarchical spec list'
  console.log '    json - single json object'
  console.log '    progress - progress bar'
  console.log '    list - spec-style listing'
  console.log '    tap - test-anything-protocol'
  console.log '    landing - unicode landing strip'
  console.log '    xunit - xunit reporter'
  console.log '    min - minimal reporter (great with --watch)'
  console.log '    json-stream - newline delimited json events'
  console.log '    markdown - markdown documentation (github flavour)'
  console.log '    nyan - nyan cat!'
  console.log()
  return

binary = path.basename pkg.bin

argv = yargs
  .usage('Usage:\n  ' + binary + ' </path/to/raml> [OPTIONS]' +
    '\n\nExample:\n  ' + binary + ' api.raml --server http://api.example.com')
  .options(Abao.options)
  .implies('template', 'generate-hooks')
  .check((argv) ->
    if argv.reporters == true
      showReporters()
      process.exit EXIT_SUCCESS

    # Ensure single positional argument present
    if argv._.length < 1
      throw new Error binary + ': must specify path to RAML file'
    else if argv._.length > 1
      throw new Error binary + ': accepts single positional command-line argument'

    return true
  )
  .wrap(80)
  .help('help', 'Show usage information and exit')
  .version().describe('version', 'Show version number and exit')
  .epilog('Website:\n  ' + pkg.homepage)
  .argv

configuration =
  'ramlPath': argv._[0],
  'options':  argv

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

