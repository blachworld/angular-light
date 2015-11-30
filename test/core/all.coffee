
console.log 'test Core'

# test $watch
Test('$watch').run ($test, alight) ->
    $test.start 1
    scope = alight.Scope()
    scope.one = 'one'

    result = null
    w = scope.$watch 'one + " " + two', (value) ->
        result = value

    scope.two = 'two'
    scope.$scan ->
        if result is 'one two'
            w.stop()
            scope.two = '2'
            scope.$scan ->
                $test.check result is 'one two'
                $test.close()
        else
            $test.error()
            $test.close()


Test('$watch #2').run ($test, alight) ->
    $test.start 2
    scope = alight.Scope()
    scope.name = 'linux'

    w0 = scope.$watch 'name', ->
    w1 = scope.$watch 'name', ->

    $test.equal w0.value, 'linux'
    $test.equal w1.value, 'linux'
    $test.close()


Test('$watch #3', 'watch-3').run ($test, alight) ->
    $test.start 20
    scope = alight.Scope()
    scope.data =
        a: 'A'
        b: 'B'

    valueA = null
    valueB = null
    countA = 0
    countB = 0
    watchA = scope.$watch 'data.a', (value) ->
        valueA = value
        countA++
    watchB = scope.$watch 'data.b', (value) ->
        valueB = value
        countB++

    scope.$scan ->
        $test.equal countA, 0
        $test.equal valueA, null
        $test.equal countB, 0
        $test.equal valueB, null

        scope.data.a = '3'
        scope.$scan ->
            $test.equal countA, 1
            $test.equal valueA, '3'
            $test.equal countB, 0
            $test.equal valueB, null

            scope.data.a = '3'
            scope.data.b = 'X'
            scope.$scan ->
                $test.equal countA, 1
                $test.equal valueA, '3'
                $test.equal countB, 1
                $test.equal valueB, 'X'

                watchA.stop()
                scope.data.a = 'Y'
                scope.data.b = 'Z'
                scope.$scan ->
                    $test.equal countA, 1
                    $test.equal valueA, '3'
                    $test.equal countB, 2
                    $test.equal valueB, 'Z'

                    watchB.stop()
                    scope.data.a = 'C'
                    scope.data.b = 'D'
                    scope.$scan ->
                        $test.equal countA, 1
                        $test.equal valueA, '3'
                        $test.equal countB, 2
                        $test.equal valueB, 'Z'
                        $test.close()


Test('$watch #4', 'watch-4').run ($test, alight) ->
    if not alight.debug.useObserver
        return $test.close()
    $test.start 5
    scope = alight.Scope()
    scope.data =
        a: 'A'
        b: 'B'

    count = 0
    w = scope.$watch 'data.a', (value) ->
        count++
    wB = scope.$watch 'data.b', (value) ->

    scope.$scan ->
        $test.equal count, 0

        scope.data.a = 'B'
        scope.$scan ->
            $test.equal count, 1

            w.stop()
            scope.data.a = 'C'

            root = scope.$system.root
            root.observer.deliver()
            $test.equal root.obList.length, 0  # no observe events
            scope.$scan ->
                $test.equal count, 1

                scope.$destroy()
                scope.data.a = 'X'
                scope.data.b = 'Y'
                root.observer.deliver()
                $test.equal root.obList.length, 0  # no observe events                
                $test.close()


Test('$watchArray').run ($test, alight) ->
    $test.start 12
    scope = alight.Scope()
    #scope.list = null

    watch = 0
    watchArray = 0

    scope.$watch 'list', ->
        watch++
    scope.$watch 'list', ->
        watchArray++
    , true

    scope.$scan ->
        $test.equal watch, 0
        $test.equal watchArray, 0

        scope.list = [1, 2, 3]
        scope.$scan ->
            $test.equal watch, 1
            $test.equal watchArray, 1

            scope.list = [1, 2]
            scope.$scan ->
                $test.equal watch, 2  # watch should fire on objects, but filter generates new object every time, that create infinity loop
                $test.equal watchArray, 2

                scope.list.push(3)
                scope.$scan ->
                    $test.equal watch, 2
                    $test.equal watchArray, 3, 'list.push 3'

                    scope.$scan ->
                        $test.equal watch, 2
                        $test.equal watchArray, 3, 'none'

                        scope.list = 7
                        scope.$scan ->
                            $test.equal watch, 3
                            $test.equal watchArray, 4, 'list = 7'
                            $test.close()


Test('$watchArray#2').run ($test, alight) ->
    $test.start 4
    scope = alight.Scope()
    #scope.list = null

    watch = 0
    watchArray = 0

    scope.$watch 'list', ->
        watch++
    scope.$watch 'list', ->
        watchArray++
    , true

    scope.$scan ->
        $test.check watch is 0 and watchArray is 0
        scope.list = []
        scope.$scan ->
            $test.check watch is 1 and watchArray is 1

            scope.list = [1, 2, 3]
            scope.$scan ->
                $test.check watch is 2 and watchArray is 2

                scope.list.push(4)
                scope.$scan ->
                    $test.check watch is 2 and watchArray is 3
                    $test.close()


Test('binding 0', 'binding-0').run ($test, alight) ->
    $test.start 4

    alight.filters.double = ->
        (value) ->
            value + value

    dom = $ '<div attr="{{ num + 5 }}">Text {{ num | double }}</div>'
    scope = alight.Scope()
    scope.num = 15

    alight.applyBindings scope, dom[0]

    $test.equal dom.text(), 'Text 30'
    $test.equal dom.attr('attr'), '20'

    scope.num = 50
    scope.$scan ->
        $test.equal dom.text(), 'Text 100'
        $test.equal dom.attr('attr'), '55'
        $test.close()


Test('test-take-attr').run ($test, alight) ->

    alight.directives.ut =
        test0:
            priority: 500
            init: (el, name, scope, env) ->
                $test.equal env.attributes[0].attrName, 'ut-test0'
                for attr in env.attributes
                    if attr.attrName is 'ut-text'
                        $test.equal attr.skip, true
                    if attr.attrName is 'ut-css'
                        $test.equal !!attr.skip, false
                $test.equal 'mo{{d}}el0', env.takeAttr 'ut-text'
                $test.equal 'mo{{d}}el1', env.takeAttr 'ut-css'

    $test.start 5
    dom = $ '<div ut-test0 ut-text="mo{{d}}el0" ut-css="mo{{d}}el1"></div>'

    scope = alight.Scope()

    alight.applyBindings scope, dom[0],
        skip_attr: ['ut-text']
    $test.close()




Test('skipped attrs').run ($test, alight) ->
    $test.start 6

    activeAttr = (env) ->
        r = for i in env.attributes
            if i.skip
                continue
            i.attrName
        r.sort().join ','

    skippedAttr = (env) ->
        r = env.skippedAttr()
        r.sort().join ','

    alight.directives.ut =
        testAttr0:
            priority: 50
            init: (el, name, scope, env) ->
                $test.equal skippedAttr(env), 'ut-test-attr0,ut-two'
                $test.equal activeAttr(env), 'one,ut-test-attr1,ut-three'
                env.takeAttr 'ut-three'
                $test.equal skippedAttr(env), 'ut-test-attr0,ut-three,ut-two'
                $test.equal activeAttr(env), 'one,ut-test-attr1'

        testAttr1:
            priority: -50
            init: (el, name, scope, env) ->
                $test.equal skippedAttr(env), 'one,ut-test-attr0,ut-test-attr1,ut-three,ut-two'
                $test.equal activeAttr(env), ''

    scope = alight.Scope()
    dom = document.createElement 'div'
    dom.innerHTML = '<div one="1" ut-test-attr1 ut-test-attr0 ut-two ut-three></div>'
    element = dom.children[0]

    alight.applyBindings scope, element,
        skip_attr: ['ut-two']
    $test.close()


Test('scope isolate').run ($test, alight) ->
    $test.start 6

    # usual
    scope = alight.Scope()
    scope.x = 5
    child = scope.$new()

    $test.equal child.x, 5
    scope.x = 7
    $test.equal child.x, 7

    # isolate
    scope = alight.Scope()
    scope.x = 5
    child = scope.$new true

    $test.equal child.x, undefined
    $test.equal child.$parent.x, 5
    scope.x = 7
    $test.equal child.x, undefined
    $test.equal child.$parent.x, 7
    $test.close()


Test('deferred process').run ($test, alight) ->
    $test.start 7

    # mock ajax
    alight.f$.ajax = (cfg) ->
        setTimeout ->
            if cfg.url is 'testDeferredProcess'
                cfg.success "<p>{{name}}</p>"
            else
                cfg.error()
        , 100

    scope5 = scope3 = null

    alight.directives.ut =
        test5:
            templateUrl: 'testDeferredProcess'
            scope: true
            link: (el, name, scope) ->
                scope5 = scope
                scope.name = 'linux'
        test3:
            templateUrl: 'testDeferredProcess'
            link: (el, name, scope) ->
                scope3 = scope
                scope.name = 'linux'

    runOne = (template) ->
        root = alight.Scope()
        root.name = 'root'

        dom = document.createElement 'div'
        dom.innerHTML = template

        alight.applyBindings root, dom

        response =
            root: root
            html: ->
                dom.innerHTML.toLowerCase()
        response

    r0 = runOne '<span ut-test5="noop"></span>'
    r1 = runOne '<span ut-test3="noop"></span>'

    setTimeout ->
        # 0
        $test.equal alight.directives.ut.test5.template, undefined
        $test.equal r0.root.name, 'root'
        $test.equal scope5.name, 'linux'
        $test.equal r0.html(), '<span ut-test5="noop"><p>linux</p></span>'
        
        # 1
        $test.equal scope3, r1.root
        $test.equal r1.root.name, 'linux'
        $test.equal r1.html(), '<span ut-test3="noop"><p>linux</p></span>'
        
        $test.close()
    , 200



Test('html prefix-data').run ($test, alight) ->
    $test.start 3

    r = []
    alight.directives.al.test = (el, value) ->
        r.push value

    dom = $ '<div> <b al-test="one"></b> <b data-al-test="two"></b> </div>'
    scope = alight.Scope()

    alight.applyBindings scope, dom[0]

    $test.equal r[0], 'one'
    $test.equal r[1], 'two'
    $test.equal r.length, 2

    $test.close()


Test('$watch $any').run ($test, alight) ->
    $test.start 15
    scope = alight.Scope()
    scope.a = 1
    scope.b = 1

    countAny = 0
    countAny2 = 0
    countA = 0

    wa = scope.$watch '$any', ->
        countAny++

    scope.$watch '$any', ->
        countAny2++

    scope.$watch 'a', ->
        countA++

    $test.equal countA, 0
    $test.equal countAny, 0
    $test.equal countAny2, 0

    scope.b++
    scope.$scan ->
        $test.equal countA, 0
        $test.equal countAny, 0
        $test.equal countAny2, 0

        scope.a++
        scope.$scan ->
            $test.equal countA, 1
            $test.equal countAny, 1
            $test.equal countAny2, 1

            wa.stop()
            scope.a++
            scope.$scan ->
                $test.equal countA, 2
                $test.equal countAny, 1
                $test.equal countAny2, 2

                scope.$destroy()
                scope.a++
                scope.$scan ->
                    $test.equal countA, 2
                    $test.equal countAny, 1
                    $test.equal countAny2, 2

                    $test.close()


Test('$watch $finishScan', 'watch-finish-scan').run ($test, alight) ->
    $test.start 20
    scope = alight.Scope()

    count0 = 0
    count1 = 0
    count2 = 0
    count3 = 0

    wa = scope.$watch '$finishScan', ->
        count0++
    scope.$watch '$finishScan', ->
        count1++
    child = scope.$new()
    wa2 = child.$watch '$finishScan', ->
        count2++
    child.$watch '$finishScan', ->
        count3++

    $test.equal count0, 0
    $test.equal count1, 0
    $test.equal count2, 0
    $test.equal count3, 0
    scope.$scan()
    alight.nextTick ->
        $test.equal count0, 1
        $test.equal count1, 1
        $test.equal count2, 1
        $test.equal count3, 1

        wa.stop()
        wa2.stop()
        scope.$scan()
        alight.nextTick ->
            $test.equal count0, 1
            $test.equal count1, 2
            $test.equal count2, 1
            $test.equal count3, 2

            child.$destroy()
            scope.$scan()
            alight.nextTick ->
                $test.equal count0, 1
                $test.equal count1, 3
                $test.equal count2, 1
                $test.equal count3, 2

                scope.$destroy()
                scope.$scan()
                alight.nextTick ->
                    $test.equal count0, 1
                    $test.equal count1, 3
                    $test.equal count2, 1
                    $test.equal count3, 2

                    $test.close()


Test('test dynamic read-only watch').run ($test, alight) ->
    $test.start 6
    scope = alight.Scope()
    scope.one = 'one'

    noop = ->
    result = null

    count = 0
    scope.$watch ->
        count++
        ''
    , noop,
        readOnly: true

    scope.$watch 'one', ->
        result

    $test.equal count, 1 # init
    scope.$scan ->
        $test.equal count, 2

        scope.one = 'two'
        scope.$scan ->
            $test.equal count, 4 # 2-loop

            scope.$scan ->
                $test.equal count, 5

                result = '$scanNoChanges'
                scope.one = 'three'
                scope.$scan ->
                    $test.equal count, 6
    
                    scope.$scan ->
                        $test.equal count, 7
                        $test.close()


Test('$watch private #0', 'watch-private-0').run ($test, alight) ->
    $test.start 8

    scope = alight.Scope()

    value = null
    count = 0
    scope.$watch 'key', (v) ->
        count++
        value = v
    ,
        private: true

    scope.$scan ->
        $test.equal count, 0
        $test.equal value, null

        scope.$system.root.private.key = 5
        scope.$scan ->
            $test.equal count, 1
            $test.equal value, 5

            scope.$system.root.private.key = 7
            scope.$scan ->
                $test.equal count, 2
                $test.equal value, 7

                root = scope.$system.root
                scope.$destroy()
                root.private.key = 11
                scope.$scan ->
                    $test.equal count, 2
                    $test.equal value, 7
                    root.private.key = 15
                    $test.close()


Test('$watch private #1', 'watch-private-1').run ($test, alight) ->
    if not alight.debug.useObserver
        return $test.close()
    $test.start 17

    _ob = []
    _unob = []
    alight.observer._objectObserve = (d, fn) ->
        _ob.push d
        Object.observe d, fn
    alight.observer._objectUnobserve = (d, fn) ->
        _unob.push d
        Object.unobserve d, fn
    #alight.observer._arrayObserve = Array.observe
    #alight.observer._arrayUnobserve = Array.unobserve

    scope = alight.Scope()

    value = null
    count = 0
    scope.$watch 'key', (v) ->
        count++
        value = v
    ,
        private: true

    fireCount = 0
    do ->
        p = scope.$system.root.privateOb
        fire = scope.$system.root.privateOb.fire
        scope.$system.root.privateOb.fire = (k, v) ->            
            fireCount++
            fire.call p, k, v

    scope.$scan ->
        $test.equal count, 0
        $test.equal value, null
        $test.equal fireCount, 0

        scope.$system.root.private.key = 5
        scope.$scan ->
            $test.equal count, 1
            $test.equal value, 5
            $test.equal fireCount, 1

            scope.$system.root.private.key = 7
            scope.$scan ->
                $test.equal count, 2
                $test.equal value, 7
                $test.equal fireCount, 2

                root = scope.$system.root
                scope.$destroy()
                root.private.key = 11
                scope.$scan ->
                    $test.equal count, 2
                    $test.equal value, 7
                    $test.equal fireCount, 2
                    root.private.key = 15

                    setTimeout ->
                        $test.equal fireCount, 2
                        $test.equal _ob.length, 2
                        $test.equal _unob.length, 2
                        $test.equal _unob.indexOf(_ob[0]) >= 0, true
                        $test.equal _unob.indexOf(_ob[1]) >= 0, true

                        $test.close()
                    , 100


Test('bootstrap $el', 'bootstrap-el').run ($test, alight) ->
    $test.start 4

    el = $("<div>{{data.name}}</div>")[0]

    app = alight.bootstrap
        $el: el
        data:
            name: 'Some text'
        click: ->
            @.data.name = 'Hello'

    $test.equal app.data.name, 'Some text'
    $test.equal el.innerText, 'Some text'

    app.click()
    app.$scan ->
        $test.equal app.data.name, 'Hello'
        $test.equal el.innerText, 'Hello'        
        $test.close()