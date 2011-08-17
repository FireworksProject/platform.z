factory = (manager) ->
    df =@getComponent('defunct_factory')
    @createService({})
    return

exports.init = (declare) ->
    return declare(null, ['defunct_factory'], factory)
