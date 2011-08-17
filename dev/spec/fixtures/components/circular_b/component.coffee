factory = (manager) ->
    manager.getComponent('circular_a')
    manager.createService({})
    return

exports.init = (declare) ->
    return declare(null, ['circular_a'], factory)
