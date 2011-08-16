jasmine = require 'jasmine-node'

exports.runTests = (opts) ->
    specpath = opts.path
    specpattern = opts.pattern or new RegExp("spec\.coffee$", "i")
    verbose = if opts.verbose then yes else no
    colored = yes

    for key, val of jasmine
        global[key] = val

    afterSpecRun = (runner, log) ->
        failures = runner.results().failedCount
        if failures then process.exit 1 else process.exit 0

    jasmine.executeSpecsInFolder(specpath, afterSpecRun, verbose, colored, specpattern)
    return
