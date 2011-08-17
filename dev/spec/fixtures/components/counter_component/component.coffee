exports.init = (declare) ->
    counter = 0
    declare null, [], ->
        counter += 1
        getCount = -> return counter
        @createComponent(getCount)
        return
    return
