fs   = require 'fs'
path = require 'path'
vm   = require 'vm'

coffee    = require 'coffee-script'
parallel  = require 'parallel'
errorUtil = require 'error-util'

FILE_EXT = ['js', 'coffee']
COFFEE_EXT_RE = /\.coffee$/

updateError = errorUtil.createUpdate('commonjs.1@kristo.us')

transportWrap = (id, text) ->
        wrapped = "\nresource('#{ id }', function (window, document) {\n"
        wrapped += text
        wrapped += "\n});\n"
        return wrapped

readFile = (filepath, callback) ->
    fs.readFile filepath, 'utf8', (err, text) ->
        if err then return callback(err)
        return callback(null, {filepath: filepath, text: text})
    return

isCoffeeScript = (filename) ->
    return COFFEE_EXT_RE.test(filename)

compileEnvironment = (basepath, main, callback) ->
    resolved = no
    fetchedSources = {}

    alreadyFetched = (id) ->
        return if fetchedSources[id] then yes else no

    fetched = (id) -> fetchedSources[id] = 2

    appendToFetch = (ids) -> for id in ids fetchedSources[id] = 0

    fetching = (id) -> fetchedSources[id] = 1

    allFetched = ->
        for own id, state of fetchedSources
            if state is 0 then return no
        return yes

    doCallback = (err, val) ->
        if resolved then return
        resolved = yes
        return callback(err, val)

    compileCoffeeScript = (id, text) ->
        try
            javascript = coffee.compile(text, {bare: true})
        catch csError
            updateError("parsing CoffeeScript '#{id}'", csError)
            return doCallback(csError)
        return javascript

    load = (texts, parent, requested) ->
        if requested.charAt(0) is '/'
            msg = "unsecure module id: '#{requested}'"
            return doCallback(updateError(msg))

        currentDir = if parent then path.dirname(parent) else basepath
        barepath = path.resolve(currentDir, requested)
        id = barepath.slice(basepath.length)

        if alreadyFetched(id) then return

        for ext in FILE_EXT
            abspath = "#{barepath}.#{ext}"
            if path.existsSync(abspath) then break

        onFileRead = (err, file) ->
            if err
                updateError("loading commonjs module '#{id}'")
                return doCallback(err)

            {filepath, text} = file
            javascript = text
            if isCoffeeScript(filepath)
                javascript = compileCoffeeScript(id, text)

            sandbox = {module: {}}
            sandbox.module.declare = (deps, factory) ->
                if parent then texts.unshift(transportWrap(id, javascript))
                else texts.push(javascript)
                fetched(id)

                if Array.isArray(deps) and deps.length
                    appendToFetch(deps)
                    load(texts, filpath, dep) for dep in deps

                if allFetched() then doCallback(null, texts.join('\n'))
                return deps

            try
                vm.runInNewContext(javascript, sandbox, id)
            catch runErr
                updateError("error executing CommonJS module '#{id}'")
                doCallback(runErr)
            return

        fetching(id)
        readFile(abspath, onFileRead)
        return

    load([], '', main)
    return

createLoader = (envtext) ->
    load = (opts, callback) ->
        compileEnvironment basepath, filename, (err, text) ->
            if err then return callback(err)
            return callback(null, envtext + text)
        return
    return load

exports.init = (declare) ->
    texts = new parallel.Dict({}, 2)

    texts.whenDone (rv) ->
        {es5Text, loaderText} = rv
        envtext = (es5Text + loaderText)

        declare null, [], ->
            @createService(createLoader(envtext))
            return
        return

    fs.readFile LOADER_PATH, 'utf8', (err, text) ->
        if err
            updateError("cannot read commonjs module loader", err)
            return declare(err)

        try
            javascript = coffee.compile(text)
        catch coffeeError
            msg = "error parsing module loader CoffeeScript"
            updateError(msg, coffeeError)
            return declare(coffeeError)

        return texts.set('loaderText', javascript)

    fs.readFile ES5_PATH, 'utf8', (err, text) ->
        if err
            updateError("cannot read es5 shim", err)
            return declare(err)
        return texts.set('es5Text', text)

    return
