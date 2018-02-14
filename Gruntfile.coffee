module.exports = (grunt) ->

  require('time-grunt') grunt

  # Dynamically load npm tasks
  require('load-grunt-config') grunt

  # Initialize configuration object
  grunt.initConfig
    # Load in the module information
    pkg: grunt.file.readJSON 'package.json'

    gruntfile: 'Gruntfile.coffee'

    clean: [
      'coverage',
      'lib/*.js'
    ]

    watch:
      options:
        spawn: false
      lib:
        files: 'lib/*.coffee'
        tasks: [
          'instrument'
          'mochaTest'
        ]
      test:
        files: 'test/**/*.coffee'
        tasks: [
          'instrument'
          'mochaTest'
        ]
      gruntfile:
        files: '<%= gruntfile %>'
        tasks: [
          'coffeelint:gruntfile'
        ]

    coffeelint:
      default:
        src: [
          'lib/*.coffee'
          'test/**/*.coffee'
        ]
      gruntfile:
        src: '<%= gruntfile %>'
      options:
        configFile: 'coffeelint.json'

    coffeecov:
      transpile:
        src: 'lib'
        dest: 'lib'

    mochaTest:
      test:
        options:
          reporter: 'mocha-phantom-coverage-reporter'
          require: 'coffee-script/register'
        src: [
          # Unit Test
          'test/unit/*-test.coffee'
          # Acceptance Test
          'test/cli-test.coffee'
        ]

    coveralls:
      upload:
        src: 'coverage/coverage.lcov'

  # Register alias tasks
  grunt.registerTask 'cover', [
    'clean',
    'instrument',
    'mochaTest'
  ]

  grunt.registerTask 'default', [
    'watch'
    'mochaTest'
  ]

  grunt.registerTask 'instrument', [ 'coffeecov' ]
  grunt.registerTask 'lint', [ 'coffeelint' ]

  grunt.registerTask 'test', [
    'lint'
    'cover'
  ]

  grunt.registerTask 'uploadCoverage', [ 'coveralls:upload' ]

  return

