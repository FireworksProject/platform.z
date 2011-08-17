factory = (manager) ->
    @getComponent('circular_b')
    @createService({})
    return

exports.init = (declare) ->
    return declare(null, ['circular_b'], factory)
