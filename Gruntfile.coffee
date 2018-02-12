module.exports = (grunt) ->

  require('time-grunt') grunt

  # Dynamically load npm tasks
  require('load-grunt-config') grunt

  grunt.initConfig

    watch:
      options:
        spawn: false
      lib:
        files: 'lib/*.coffee'
        tasks: [
          'coffeecov'
          'mochaTest'
        ]
      test:
        files: 'test/**/*.coffee'
        tasks: [
          'coffeecov'
          'mochaTest'
        ]
      gruntfile:
        files: 'Gruntfile.coffee'
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
        src: 'Gruntfile.coffee'
      options:
        configFile: 'coffeelint.json'

    coffeecov:
      compile:
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

    shell:
      coveralls:
        command: './node_modules/coveralls/bin/coveralls.js lib < coverage/coverage.lcov'

  grunt.registerTask 'uploadCoverage', ->
    grunt.task.run 'shell:coveralls'

  grunt.registerTask 'default', [
    'watch'
    'mochaTest'
  ]

  grunt.registerTask 'test', [
    'coffeelint'
    'coffeecov'
    'mochaTest'
  ]

  return

