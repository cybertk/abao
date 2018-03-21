module.exports = (grunt) ->

  'use strict'
  require('time-grunt') grunt

  # Dynamically load npm tasks
  require('load-grunt-config') grunt

  # Initialize configuration object
  grunt.initConfig
    # Load in the module information
    pkg: grunt.file.readJSON 'package.json'

    readme: 'README.md'
    gruntfile: 'Gruntfile.coffee'

    clean:
      cover: [
        'coverage'
      ],
      instrumented: [
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
      options:
        configFile: 'coffeelint.json'
      default:
        src: [
          'lib/*.coffee'
          'test/**/*.coffee'
        ]
      gruntfile:
        src: '<%= gruntfile %>'

    markdownlint:
      options:
        config: require './.markdownlint.json'
      default:
        src: [
          '<%= readme %>'
        ]

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
          'test/unit/*-test.coffee'
          'test/e2e/cli-test.coffee'
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
  grunt.registerTask 'lint', [
    'coffeelint',
    'markdownlint'
  ]

  grunt.registerTask 'test', [
    'lint'
    'cover'
  ]

  return

