exports.init = (declare) ->
    counter = 0
    declare null, [], ->
        counter += 1
        getCount = -> return counter
        @createService(getCount)
        return
    return
