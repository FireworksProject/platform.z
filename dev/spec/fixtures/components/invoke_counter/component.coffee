exports.init = (declare) ->
    declare null, ['counter_service', 'counter_component'], ->
        @getComponent('counter_service')
        @getComponent('counter_service')
        svc = @getComponent('counter_service')
        @getComponent('counter_component')
        @getComponent('counter_component')
        cmp = @getComponent('counter_component')
        @createComponent({serviceCount: svc(), componentCount: cmp()})
        return
    return
