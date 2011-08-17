render = (abspath, data, callback) ->
    return

exports.init = (declare) ->
    declare null, [], ->
        @createService(render)
        return
    return
