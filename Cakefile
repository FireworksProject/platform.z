path = require 'path'

testrunner = require './dev/node_lib/testrunner'

SPEC_PATH = path.join(__dirname, 'dev', 'spec')

task 'test', 'run the full spec test suite', (options)->
    runnerOptions =
        path: SPEC_PATH
        verbose: yes

    testrunner.runTests(runnerOptions)
    return
