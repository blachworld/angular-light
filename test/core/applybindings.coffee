
Test('apply_bindings', 'apply-binding-0').run ($test, alight) ->
    $test.start 12
    f$ = alight.f$

    el = document.createElement('div')
    count = 0
    scope =
        link: 'img.jpg'
        redClass: false
        testInit: ->
            count += 1

    cd = alight.ChangeDetector scope

    f$.attr el, 'al-init', 'testInit()'
    f$.attr el, 'al-css', 'red: redClass'
    f$.attr el, 'al-src', 'some-{{link}}'
    f$.attr el, 'some-text', 'start:{{link}}:finish'
    alight.applyBindings cd, el

    $test.equal el.className, ''
    $test.equal f$.attr el, 'src', 'some-img.jpg'
    $test.equal count, 1
    $test.equal f$.attr el, 'some-text', 'start:img.jpg:finish'

    cd.scan ->
        $test.equal el.className, ''
        $test.equal f$.attr el, 'src', 'some-img.jpg'
        $test.equal count, 1
        $test.equal f$.attr el, 'some-text', 'start:img.jpg:finish'

        scope.redClass = true
        scope.link = 'other.png'
        cd.scan ->
            $test.equal el.className, 'red'
            $test.equal f$.attr el, 'src', 'some-other.png'
            $test.equal count, 1
            $test.equal f$.attr el, 'some-text', 'start:other.png:finish'

            $test.close()


Test('bootstrap $el', 'bootstrap-el').run ($test, alight) ->
    $test.start 4

    el = $("<div>{{data.name}}</div>")[0]

    cd = alight.bootstrap
        $el: el
        data:
            name: 'Some text'
        click: ->
            @.data.name = 'Hello'

    scope = cd.scope
    $test.equal scope.data.name, 'Some text'
    $test.equal el.innerText, 'Some text'

    scope.click()
    cd.scan ->
        $test.equal scope.data.name, 'Hello'
        $test.equal el.innerText, 'Hello'        
        $test.close()
