jqtpl     = require 'jqtpl'
processor = require './preparser'

render = (abspath, data, callback) ->
    processor.preProcess abspath, (err, text) ->
        if (err) then return callback(err)

        data or= {}
        html = ''

        try
            html = jqtpl.tmpl(text, data)
        catch jqtplError
            return callback(jqtplError)

        return callback(null, html)
    return

exports.init = (declare) ->
    declare null, [], ->
        @createService(render)
        return
    return
