exports.init = (declare) ->
    counter = 0
    declare null, [], ->
        getValue = -> return 4
        @createService({val: getValue})
        return
    return
