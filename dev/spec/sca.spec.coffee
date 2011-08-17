path = require 'path'

sca = require '../../node_lib/sca'

FIXTURES = path.join(__dirname, 'fixtures')
COMPATH  = path.join(FIXTURES, 'components')

describe 'component manager', ->

    it 'should pass an error in the case of unhandled circular dependencies', ->
        result = null
        gotResult = -> return result
        sca.startManager {libpath: COMPATH, main: 'circular_a'}, (err) ->
            result = if err then err or true

        waitsFor(gotResult, 'circular dependency', 100)
        runs ->
            msg = "circular dependency required from 'circular_b' to 'circular_a'"
            expect((result or {}).message).toBe(msg)
            return
        return

    return


describe 'startManager() invalid parameter handling', ->

    it 'should throw when an invalid libpath is passed', ->
        doit = ->
            return sca.startManager({main: 'foo'})

        expect(doit).toThrow("invalid 'libpath' option passed")
        return

    it 'should throw when an invalid main path is passed', ->
        doit = ->
            return sca.startManager({libpath: 'foo'})

        expect(doit).toThrow("invalid 'main' option passed")
        return

    it 'should pass an error when the main module is missing', ->
        result = null
        gotResult = -> return result
        sca.startManager {libpath: 'foo', main: 'bar'}, (err) ->
            result = if err then err or true

        waitsFor(gotResult, 'missing main module', 100)
        runs ->
            msg = "load component require() error: Cannot find module 'foo/bar/component'"
            expect((result or {}).message).toBe(msg)
            return
        return

    return

describe 'component manager invalid definition handling', ->

    it 'should pass an error when a module is not named by convention', ->
        result = null
        gotResult = -> return result
        sca.startManager {libpath: COMPATH, main: 'invalid'}, (err) ->
            result = if err then err or true

        waitsFor(gotResult, 'invalid module name', 100)
        runs ->
            msgpath = path.join(COMPATH, 'invalid', 'component')
            msg = "load component require() error: Cannot find module '#{msgpath}'"
            expect((result or {}).message).toBe(msg)
            return
        return

    it 'should pass an error with an invalid component definition', ->
        result = null
        gotResult = -> return result
        sca.startManager {libpath: COMPATH, main: 'invalid_definition'}, (err) ->
            result = if err then err or true

        waitsFor(gotResult, 'invalid module definition', 100)
        runs ->
            msg = "definition for 'invalid_definition' does not export init()"
            expect((result or {}).message).toBe(msg)
            return
        return

    it 'should pass an error when declare function is passed an error', ->
        result = null
        gotResult = -> return result
        sca.startManager {libpath: COMPATH, main: 'init_error'}, (err) ->
            result = if err then err or true

        waitsFor(gotResult, 'init error', 100)
        runs ->
            msg = "testing init error"
            expect((result or {}).message).toBe(msg)
            return
        return

    it 'should pass an error when dependencies are not defined', ->
        result = null
        gotResult = -> return result
        sca.startManager {libpath: COMPATH, main: 'invalid_deps'}, (err) ->
            result = if err then err or true

        waitsFor(gotResult, 'invalid dependencies', 100)
        runs ->
            msg = "invalid dependencies definition 'undefined' in 'invalid_deps'"
            expect((result or {}).message).toBe(msg)
            return
        return

    it 'should pass an error when the factory function is not defined', ->
        result = null
        gotResult = -> return result
        sca.startManager {libpath: COMPATH, main: 'invalid_factory'}, (err) ->
            result = if err then err or true

        waitsFor(gotResult, 'invalid factory function', 100)
        runs ->
            msg = "invalid factory function definition '[object Boolean]' in 'invalid_factory'"
            expect((result or {}).message).toBe(msg)
            return
        return

    it 'should pass an error if a component is not created by the factory', ->
        result = null
        gotResult = -> return result
        sca.startManager {libpath: COMPATH, main: 'defunct_factory'}, (err) ->
            result = if err then err or true

        waitsFor(gotResult, 'defunct factory function', 100)
        runs ->
            msg = "component factory for 'defunct_factory' did not create a component"
            expect((result or {}).message).toBe(msg)
            return
        return

    it 'should pass a factory error up the dependency chain', ->
        result = null
        gotResult = -> return result
        sca.startManager {libpath: COMPATH, main: 'factory_chain_error'}, (err) ->
            result = if err then err or true

        waitsFor(gotResult, 'factory chain error', 100)
        runs ->
            msg = "component factory for 'defunct_factory' did not create a component"
            expect((result or {}).message).toBe(msg)
            return
        return

    return

describe 'manager.getComponent()', ->

    it 'should throw an error if the passed component id does not exist', ->
        result = null
        gotResult = -> return result
        sca.startManager {libpath: COMPATH, main: 'component_na'}, (err) ->
            result = if err then err or true

        waitsFor(gotResult, 'component not available', 100)
        runs ->
            msg = "component 'foobar' is not available"
            expect((result or {}).message).toBe(msg)
            return
        return
