factory = (manager) ->
    manager.getComponent('foobar')
    return

exports.init = (declare) ->
    return declare(null, [], factory)
