module.exports = (grunt) ->

  require('time-grunt') grunt

  # Dynamically load npm tasks
  require('jit-grunt') grunt

  grunt.initConfig

    # Watching changes files *.coffee,
    watch:
      all:
        files: [
          "Gruntfile.coffee"
          "src/**/*.coffee"
          "test/**/*.coffee"
        ]
        tasks: [
          "mochaTest"
        ]
        options:
          nospawn: true

    coffeelint:
      default:
        src: [
          'Gruntfile.coffee'
          'src/**/*.coffee'
          'test/**/*.coffee'
        ]
      options: {
        configFile: 'coffeelint.json'
      }

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
          'test/unit/*.coffee'
          # Acceptance Test
          'test/cli-test.coffee'
        ]

    shell:
      coveralls:
        command: 'cat coverage/coverage.lcov | ./node_modules/coveralls/bin/coveralls.js lib'

  grunt.registerTask 'uploadCoverage', ->
    grunt.task.run 'shell:coveralls'

  grunt.registerTask "default", [
    "watch"
    "mochaTest"
  ]

  grunt.registerTask "test", [
    "coffeelint"
    "coffeecov"
    "mochaTest"
  ]

  return
