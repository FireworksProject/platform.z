factory = (manager) ->
    manager.getComponent('circular_b')
    manager.createService({})
    return

exports.init = (declare) ->
    return declare(null, ['circular_b'], factory)
