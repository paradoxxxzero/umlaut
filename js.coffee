Vec2 = Box2D.Common.Math.b2Vec2
BodyDef = Box2D.Dynamics.b2BodyDef
Body = Box2D.Dynamics.b2Body
FixtureDef = Box2D.Dynamics.b2FixtureDef
Fixture = Box2D.Dynamics.b2Fixture
World = Box2D.Dynamics.b2World
MassData = Box2D.Collision.Shapes.b2MassData
PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
CircleShape = Box2D.Collision.Shapes.b2CircleShape
DebugDraw = Box2D.Dynamics.b2DebugDraw
DistanceJointDef = Box2D.Dynamics.Joints.b2DistanceJointDef
MouseJointDef = Box2D.Dynamics.Joints.b2MouseJointDef

scaleFactor = 30
box_restitution = .1
box_density = 2
box_friction = .9
box_linearDampling = .5
box_angularDampling = 2
spring_frequency = 2
spring_damping_ratio = .2
spring_length = 10
gravity_x = 0
gravity_y = 10

window.onload = ->
    ww = window.innerWidth
    wh = window.innerHeight
    mouse =
        x: 0
        y: 0
        joint: null
    boxes = []
    debug = false
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
    debugLayer = new Kinetic.Layer()

    makeWorld = ->
        new World(new Vec2(gravity_x, gravity_y), true)


    makeDrawer = (world) ->
        drawer = new DebugDraw()
        drawer.SetSprite debugLayer.context
        drawer.SetDrawScale scaleFactor
        drawer.SetFillAlpha .5
        drawer.SetLineThickness 1.0
        drawer.SetFlags DebugDraw.e_shapeBit | DebugDraw.e_jointBit
        world.SetDebugDraw drawer
        drawer

    makeWall = (world) ->
        # Create border of boxes
        wall = new PolygonShape()
        wallBd = new BodyDef()
        bw = ww / 30
        bh = wh / 30
        
        # Left
        wallBd.position.Set .25, 0
        wall.SetAsBox .25, bh
        wallLeft = world.CreateBody(wallBd)
        wallLeft.CreateFixture2 wall

        # Right
        wallBd.position.Set bw - .25, 0
        wallRight = world.CreateBody(wallBd)
        wallRight.CreateFixture2 wall

        # Top
        wallBd.position.Set 0, .25
        wall.SetAsBox bw, .25
        _wallTop = world.CreateBody(wallBd)
        _wallTop.CreateFixture2 wall

        # Bottom
        wallBd.position.Set 0, bh - .25
        _wallBottom = world.CreateBody(wallBd)
        _wallBottom.CreateFixture2 wall

    makeBox = (world, x, y, text, pinned=false) ->
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
        box = links: []
        box.group = new Kinetic.Group
            draggable: pinned
            x: x
            y: y
            scale:
                x: 1
                y: 1
            offset: [w / 2, h / 2]
            selected: false
            select: (add) ->
                if linkMaking
                    for selectedbox in selection
                        makeLink world, selectedbox, box
                    linkMaking = false
                if not add
                    boxes.map (b) -> b.group.attrs.unselect()
                selection.push(box)
                rect.setAttrs
                    shadow:
                        color: 'blue'
                        blur: 10
                        offset: [5, 5]
                        alpha: 0.6
                box.group.attrs.selected = true
                box.group.moveToTop()
                boxLayer.draw()
            unselect: ->
                selection.splice(box)
                rect.setAttrs
                    shadow:
                        color: 'black'
                        blur: 10
                        offset: [5, 5]
                        alpha: 0.6
                box.group.attrs.selected = false
                boxLayer.draw()

            rect: rect
            text: text

        box.group.add rect
        box.group.add text

                
        bodyDef = new BodyDef()
        bodyDef.type = if pinned then Body.b2_kinematicBody else Body.b2_dynamicBody
        bodyDef.position.Set box.group.attrs.x / scaleFactor, box.group.attrs.y / scaleFactor
        bodyDef.angle = 0
        bodyDef.angularDamping = box_angularDampling
        bodyDef.linearDamping = box_linearDampling
        box.body = world.CreateBody(bodyDef)
        box.body.w = w / (2 * scaleFactor)
        box.body.h = h / (2 * scaleFactor)
        shape = new PolygonShape.AsBox(box.body.w, box.body.h)
        fixtureDef = new FixtureDef()
        fixtureDef.restitution = box_restitution
        fixtureDef.density = box_density
        fixtureDef.friction = box_friction
        fixtureDef.shape = shape
        box.body.CreateFixture fixtureDef

        text.on "dblclick", ->
            txt = prompt "Enter the name", text.attrs.text
            if txt
                text.setAttrs text: txt
                rect.setAttrs width: text.textWidth + 20

        box.group.on "mousedown", (e) ->
            if box.group.attrs.selected
                box.group.attrs.unselect()
            else
                box.group.attrs.select(e.shiftKey)
            if not mouse.joint
                joint = new MouseJointDef();
                joint.bodyA = world.GetGroundBody()
                joint.bodyB = box.body
                joint.target = new Vec2 mouse.x / scaleFactor, mouse.y / scaleFactor
                joint.collideConnected = true;
                joint.maxForce = 300 * box.body.GetMass()
                mouse.joint = world.CreateJoint(joint)
                box.body.SetAwake(true)
                
            
        box.group.on "dragstart", ->
            if box.body.GetType() == Body.b2_dynamicBody
                return false
            trans.stop()  if trans
            box.group.moveToTop()
            rect.setAttrs
                shadow:
                    offset:
                        x: 15
                        y: 15

            box.group.setAttrs
                scale:
                    x: 1.4
                    y: 1.4

        box.group.attrs.moved = ->
            for link in box.links
                points = link.line.getPoints()
                points[link.side].x = box.group.attrs.x
                points[link.side].y = box.group.attrs.y
                link.line.setPoints points

        box.group.on "dragmove", (e) ->
            box.body.SetPosition x: box.group.attrs.x / scaleFactor, y: box.group.attrs.y / scaleFactor
            box.group.attrs.moved()

        box.group.on "dragend", ->
            rect.setAttrs
                shadow:
                    offset:
                        x: 5
                        y: 5

            trans = box.group.transitionTo
                duration: 0.5
                easing: "elastic-ease-out"
                scale:
                    x: 1
                    y: 1


        boxLayer.add box.group
        boxes.push box
        boxLayer.draw() if started
        box


    makeLink = (world, box1, box2)->

        line = new Kinetic.Line
            points: [box1.group.attrs.x, box1.group.attrs.y, box2.group.attrs.x, box2.group.attrs.y]
            stroke: "black"
            strokeWidth: 1.5 
            lineCap: "round"
            lineJoin: "round"

        spring = new DistanceJointDef()
        spring.bodyA = box1.body
        spring.bodyB = box2.body
        spring.frequencyHz = spring_frequency
        spring.dampingRatio = spring_damping_ratio
        spring.localAnchorA = new Vec2(0, - .33)
        spring.localAnchorB = new Vec2(0, - .33)
        spring.length = spring_length
        world.CreateJoint spring

        box1.links.push
            line: line
            spring: spring
            side: 0

        box2.links.push
            line: line
            spring: spring
            side: 1
            
        lineLayer.add line
        lineLayer.draw() if started
        line


    stage.add lineLayer
    stage.add boxLayer
    stage.add debugLayer
    window.ll = lineLayer
    window.bl = boxLayer

    window.document.body.onmousemove = (e) ->
        mouse.x = e.clientX
        mouse.y = e.clientY
        if mouse.joint
            mouse.joint.SetTarget new Vec2 mouse.x / scaleFactor, mouse.y / scaleFactor

    window.document.body.onmouseup = (e) ->
        if mouse.joint
            world.DestroyJoint mouse.joint
            mouse.joint = null
        
    window.onkeydown = (e) ->
        if e.keyCode == 78  # n
            makeBox world, mouse.x, mouse.y, ('Box #' + boxes.length)
        else if e.keyCode == 76  # l
            if not linkMaking
                linkMaking = true
        else if e.keyCode == 83  # s
            for box in selection
                box.body.SetType Body.b2_kineticBody
                box.group.setDraggable true
        else if e.keyCode == 82  # r
            for box in selection
                box.body.SetType Body.b2_dynamicBody
                box.group.setDraggable false
        else if e.keyCode == 90  # z
            for box in selection
                box.body.SetAngle 0
        else if e.keyCode == 68  # d
            debug = not debug
            if not debug
                debugLayer.clear()
        else
            boxLayer.draw()
            lineLayer.draw()

    world = makeWorld()
    drawer = makeDrawer world
    makeWall world
    
    makeBox world, ww / 2, wh / 3, ('Box #' + boxes.length), true
    makeBox world, ww / 3, wh / 2, ('Box #' + boxes.length)
    makeBox world, 2 * ww / 3, wh / 2, ('Box #' + boxes.length)
    makeLink world, boxes[0], boxes[1]
    makeLink world, boxes[0], boxes[2]
    makeLink world, boxes[1], boxes[2]
    
    started = true
    boxLayer.draw()
    lineLayer.draw()

    animloop = ->
        (window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame) animloop
        render drawer

    lastTime = new Date().getTime()
    velocity = 300
    position = 200

    render = ->
        time = new Date().getTime()
        delta = (time - lastTime) / 1000
        lastTime = time
        world.Step delta, delta * velocity, delta * position
        if debug
            world.DrawDebugData()
        for box in boxes
            pos = box.body.GetPosition()
            box.group.setX pos.x * scaleFactor
            box.group.setY pos.y * scaleFactor
            box.group.setRotation box.body.GetAngle()
            box.group.attrs.moved()

        boxLayer.draw()
        lineLayer.draw()
        world.ClearForces()

    animloop()
