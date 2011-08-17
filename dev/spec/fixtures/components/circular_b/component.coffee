factory = (manager) ->
    @getComponent('circular_a')
    @createService({})
    return

exports.init = (declare) ->
    return declare(null, ['circular_a'], factory)
