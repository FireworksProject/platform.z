factory = (manager) ->
    df = manager.getComponent('defunct_factory')
    manager.createService({})
    return

exports.init = (declare) ->
    return declare(null, ['defunct_factory'], factory)
