module.exports = (grunt) ->

  require('time-grunt') grunt

  ###
  Dynamically load npm tasks
  ###
  require('jit-grunt') grunt

  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-mocha-test');

  grunt.initConfig

    # Watching changes files *.js,
    watch:
      all:
        files: [
          "Gruntfile.coffee"
          "src/**/*.coffee"
          "test/**/*.coffee"
        ]
        tasks: [
          "coffee"
          "mochaTest"
        ]
        options:
          nospawn: true

    coffee:
      compile:
        expand: true,
        flatten: true,
        src: ['src/*.coffee'],
        dest: 'lib/',
        ext: '.js'

    mochaTest:
      test:
        options:
          reporter: 'spec'
          require: 'coffee-script/register'
        src: ['test/**/*.coffee']

  grunt.registerTask "default", [
    "watch"
    "mochaTest"
  ]

  grunt.registerTask "test", [
    "coffee"
    "mochaTest"
  ]

  return
