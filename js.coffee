window.onload = ->
    ww = window.innerWidth
    wh = window.innerHeight
    mouse =
        x: 0
        y: 0
    boxes = []
    linkMaking = false
    started = false
    selection = []
    window.selection = selection
    stage = new Kinetic.Stage
        container: "container"
        width: ww
        height: wh

    boxLayer = new Kinetic.Layer()
    lineLayer = new Kinetic.Layer()

    makeBox = (x, y, text) ->
        trans = null

        text = new Kinetic.Text
            x: 1
            y: 1
            text: text
            stroke: '#555'
            strokeWidth: 1
            fill: '#ddd'
            fontSize: 14
            fontFamily: 'Calibri'
            fontStyle: 'normal'
            textFill: '#555'
            padding: 10
            align: 'center'
            # cornerRadius: 10

        w = text.textWidth + 22
        h = 150
        rect = new Kinetic.Rect
            x: 0
            y: 0
            width: w
            height: h
            fill: "#eee"
            stroke: "#333"
            alpha: 1
            strokeWidth: 2
            shadow:
                color: "black"
                blur: 10
                offset: [5, 5]
                alpha: 0.6
            # cornerRadius: 10

        box = new Kinetic.Group
            draggable: true
            x: x + w / 2
            y: y + h / 2
            scale:
                x: 1
                y: 1
            offset: [w / 2, h / 2]
            links: []
            selected: false
            select: (add) ->
                if linkMaking
                    for selectedbox in selection
                        makeLink selectedbox, box
                    linkMaking = false
                if not add
                    boxes.map (b) -> b.attrs.unselect()
                selection.push(box)
                rect.setAttrs
                    shadow:
                        color: 'blue'
                        blur: 10
                        offset: [5, 5]
                        alpha: 0.6
                box.attrs.selected = true
                box.moveToTop()
                boxLayer.draw()
            unselect: ->
                selection.splice(box)
                rect.setAttrs
                    shadow:
                        color: 'black'
                        blur: 10
                        offset: [5, 5]
                        alpha: 0.6
                box.attrs.selected = false
                boxLayer.draw()

            rect: rect
            text: text

        box.add rect
        box.add text

        text.on "click", ->
            txt = prompt "Enter the name", text.attrs.text
            if txt
                text.setAttrs text: txt
                rect.setAttrs width: text.textWidth + 20

        box.on "click", (e) ->
            if box.attrs.selected
                box.attrs.unselect()
            else
                box.attrs.select(e.shiftKey)

            
        box.on "dragstart", ->
            trans.stop()  if trans
            box.moveToTop()
            rect.setAttrs
                shadow:
                    offset:
                        x: 15
                        y: 15

            box.setAttrs
                scale:
                    x: 1.4
                    y: 1.4

        box.on "dragmove", (e) ->
            for link in box.attrs.links
                points = link.line.getPoints()
                points[link.side].x = box.attrs.x
                points[link.side].y = box.attrs.y
                link.line.setPoints points
            lineLayer.draw()

        box.on "dragend", ->
            rect.setAttrs
                shadow:
                    offset:
                        x: 5
                        y: 5

            trans = box.transitionTo
                duration: 0.5
                easing: "elastic-ease-out"
                scale:
                    x: 1
                    y: 1

        boxLayer.add box
        boxes.push box
        boxLayer.draw() if started
        box


    makeLink = (box1, box2)->

        line = new Kinetic.Line
            points: [box1.attrs.x, box1.attrs.y, box2.attrs.x, box2.attrs.y]
            stroke: "black"
            strokeWidth: 1.5 
            lineCap: "round"
            lineJoin: "round"

        box1.attrs.links.push
            line: line
            side: 0

        box2.attrs.links.push
            line: line
            side: 1

        lineLayer.add line
        lineLayer.draw() if started
        line


    stage.add lineLayer
    stage.add boxLayer
    window.ll = lineLayer
    window.bl = boxLayer

    window.document.body.onmousemove = (e) ->
        mouse.x = e.x
        mouse.y = e.y

    window.onkeydown = (e) ->
        if e.keyCode == 78  # n
            makeBox mouse.x, mouse.y, ('Box #' + boxes.length)
        else if e.keyCode == 76  # l
            if not linkMaking
                linkMaking = true
        else
            boxLayer.draw()
            lineLayer.draw()

    makeBox 100, 100, ('Box #' + boxes.length) 
    makeBox 400, 200, ('Box #' + boxes.length)
    makeLink boxes[0], boxes[1]
    started = true
    boxLayer.draw()
    lineLayer.draw()
