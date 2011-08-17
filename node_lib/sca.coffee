path = require 'path'

# Utility mostly used for error reporting
typestr = (obj) ->
    if typeof obj is 'undefined' then return 'undefined'
    if obj is null then return 'null'
    return Object.prototype.toString.call(obj)

#
# Component Classes
#

class Component
    constructor: (@component) ->


class ServiceComponent extends Component
    type: 'service'

    wrap: ->
        wrappedComponent = Object.create(@component)
        for own name, p of wrappedComponent
            if typeof p isnt 'function'
                delete wrappedComponent[name]
        return wrappedComponent


class ConstructorComponent extends Component
    type: 'constructor'

    wrap: ->
        if not @makeAbstractDataType
            @makeAbstractDataType = (spec) =>
                abstractDataInstnace = @component(spec)
                for own name, p of abstractDataInstnace
                    if typeof p is 'function'
                        delete abstractDataInstnace[name]
                return abstractDataInstnace

        return @makeAbstractDataType


class MiddlewareComponent extends Component
    type: 'middleware'

    wrap: ->
        if not @middleware
            @middleware = (spec) =>
                fn = @component(spec)
                return createMiddleware(fn)
        return @middleware


# Wrap a middleware function in a proxy (used by MiddlewareComponent)
createMiddleware = (fn) ->
    middleware = (opts, callback) ->
        process.nextTick ->
            fn opts, ->
                callback.apply({}, arguments)
                return
            return
        return
    return middleware


# @constructor Loader
# Create a component loader function/object in a closure
exports.createLoader = (opts) ->
    basepath = opts.basepath
    factories = {}
    components = {}

    memoizeFactory = (id, def) ->
        factories[id] = def
        return

    factoryMemoized = (id) ->
        if factories[id] then return true else return false

    resolveId = (id) ->
        return path.join(basepath, id, 'component')

    provideComponent = (id, factory, deps, callback) ->
        memoizeFactory(id, factory)
        provideDependencies(deps, callback)
        return

    provideDependencies = (deps, callback) ->
        if not deps.length
            return callback()
        id = deps.pop()
        if factoryMemoized(id)
            return provideDependencies(deps, callback)
        load id, ->
            return provideDependencies(deps, callback)
        return

    load = (id, callback) ->
        abspath = resolveId(id)
        try
            mod = require(abspath)
        catch requireErr
            msg = "load component require() error: #{requireErr.message}"
            requireErr.message = msg
            return callback(requireErr)

        if typeof mod.init isnt 'function'
            msg = "definition for '#{id}' does not export init()"
            return callback(new Error(msg))

        mod.init (err, deps, factory) ->
            if err then return callback(err)

            if not Array.isArray(deps)
                msg = "invalid dependencies definition "
                msg += "'#{typestr(deps)}' in '#{id}'"
                return callback(new Error(msg))

            if typeof factory isnt 'function'
                msg = "invalid factory function definition "
                msg += "'#{typestr(factory)}' in '#{id}'"
                return callback(new Error(msg))

            return provideComponent(id, factory, deps, callback)

        return

    getComponent = (from, id) ->
        comp = components[id]

        if comp is null
            msg = "circular dependency required from '#{from}' to '#{id}'"
            throw new Error(msg)

        if typeof comp is 'undefined'
            comp = initializeComponent(id)

        return comp.wrap()

    initializeComponent = (id) ->
        factory = factories[id]
        
        if not factory
            msg = "component '#{id}' is not available"
            throw new Error(msg)

        spec = {id: id}
        components[id] = null
        factory(createManagerInterface(spec))
        comp = components[id]

        if not comp
            msg = "component factory for '#{id}' did not create a component"
            throw new Error(msg)

        return comp

    createManagerInterface = (spec) ->
        interface = {}
        id = spec.id

        interface.getComponent = (target) ->
            return getComponent(id, target)

        interface.createService = (service) ->
            components[id] = new ServiceComponent(service)
            return

        interface.createConstructor = (fn) ->
            components[id] = new ConstructorComponent(fn)
            return

        interface.createMiddleware = (fn) ->
            components[id] = new MiddlewareComponent(fn)
            return

        return interface

    # create and return the component loader object function
    self = (main, callback) ->
        load main, (err) ->
            if err then return callback(err)

            try
                mainComponent = getComponent('COMPONENT_MANAGER', main)
            catch compErr
                return callback(compErr)

            return callback(null, mainComponent)

        return

    return self


#
# Public API
#
# @param opts.libpath The path to the component library
# @param opts.main The name of the main bootstrap component to load
# @param callback A callback function to be called after loading
#   callback(<error>, <main component>)
#
# The callback will be called after the main component and all dependencies
# have been loaded. In case of an error, it will be called with the error
# object as the first parameter. On successful load, the error parameter will
# be null and the second paramter will be the main component object.
#
exports.startManager = (opts, callback) ->
    opts     or= {}
    callback or= ->
    libpath    = opts.libpath
    main       = opts.main

    if not libpath or typeof libpath isnt 'string'
        msg = "invalid 'libpath' option passed"
        throw new Error(msg)

    if not main or typeof main isnt 'string'
        msg = "invalid 'main' option passed"
        throw new Error(msg)

    loader = exports.createLoader({basepath: libpath})
    loader(main, callback)
    return
