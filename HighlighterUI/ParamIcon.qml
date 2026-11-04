import QtQuick
import QtQuick.Shapes

/// A drawn transport icon, hard-edged, every one on the same size so a row
/// of them lines up: "play", "back" (play reversed), "pause", "stop",
/// "record", "rewind" and "forward" (the double triangles), "prev" and
/// "next" (a triangle to a bar); and an animation's modes: "loop" (round
/// and round), "bounce" (↔), "once" (→, then back to the start), "hold"
/// (→|, stays at the end), "animate" (a ball moving, a slider's animate mark) and
/// "pencil" (edit a curve).
/// ParamButton draws one when its `icon` is one of these names.
Item {
    id: icon

    property string name: "play"
    property color color: Theme.arrow
    //! The icon's height; widths follow from it.
    property real size: Theme.s(12)

    //! Every name it draws (ParamButton checks against this).
    readonly property var names: ["play", "back", "pause", "stop", "record", "rewind", "forward", "prev", "next",
                                  "loop", "bounce", "once", "hold", "animate", "pencil"]
    readonly property real s: icon.size
    // a stroke's thickness, for the line icons
    readonly property real t: Math.max(2, Math.round(s * 0.17))
    // each icon's natural width, so a button sizes round it
    width: name === "pause" ? Math.round(s * 0.8)
         : name === "stop" || name === "record" ? Math.round(s * 0.9)
         : name === "rewind" || name === "forward" ? Math.round(s * 1.3)
         : name === "prev" || name === "next" ? Math.round(s * 0.95)
         : name === "loop" ? Math.round(s * 1.3)
         : name === "once" ? Math.round(s * 1.15)
         : name === "bounce" || name === "hold" ? Math.round(s * 1.3)
         : name === "animate" ? Math.round(s * 1.5)
         : name === "pencil" ? Math.round(s * 1.1)
         : Math.round(s * 0.85)   // play
    height: Math.round(s)

    // --- play: one triangle, full height (back: pointing left) -------------------
    Shape {
        visible: icon.name === "play" || icon.name === "back"
        transform: Scale { origin.x: icon.width / 2; xScale: icon.name === "back" ? -1 : 1 }
        width: icon.width; height: icon.height
        preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
        antialiasing: Theme.smooth
        ShapePath {
            strokeWidth: -1; fillColor: icon.color
            startX: 0; startY: 0
            PathLine { x: icon.width; y: icon.height / 2 }
            PathLine { x: 0; y: icon.height }
            PathLine { x: 0; y: 0 }
        }
    }

    // --- pause: two bars, close together ----------------------------------------
    Rectangle { visible: icon.name === "pause"; width: Math.round(icon.width * 0.36); height: icon.height; color: icon.color }
    Rectangle { visible: icon.name === "pause"; x: icon.width - width; width: Math.round(icon.width * 0.36); height: icon.height; color: icon.color }

    // --- stop: a square; record: a dot ------------------------------------------
    Rectangle {
        visible: icon.name === "stop" || icon.name === "record"
        anchors.centerIn: parent
        width: icon.width; height: width
        radius: icon.name === "record" ? width / 2 : 0
        antialiasing: Theme.smooth
        color: icon.name === "record" ? Theme.danger : icon.color
    }

    // --- rewind / forward: two triangles nose to tail -----------------------------
    Repeater {
        model: icon.name === "rewind" || icon.name === "forward" ? 2 : 0
        Shape {
            id: tri
            required property int index
            readonly property bool back: icon.name === "rewind"
            x: index * icon.width / 2
            width: icon.width / 2; height: icon.height
            preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
            antialiasing: Theme.smooth
            ShapePath {
                strokeWidth: -1; fillColor: icon.color
                startX: tri.back ? tri.width : 0; startY: 0
                PathLine { x: tri.back ? 0 : tri.width; y: icon.height / 2 }
                PathLine { x: tri.back ? tri.width : 0; y: icon.height }
                PathLine { x: tri.back ? tri.width : 0; y: 0 }
            }
        }
    }

    // --- prev / next: a triangle against a bar ------------------------------------
    Item {
        id: step
        visible: icon.name === "prev" || icon.name === "next"
        anchors.fill: parent
        readonly property bool back: icon.name === "prev"
        readonly property real bar: Math.max(2, Math.round(icon.s * 0.2))
        Rectangle { x: step.back ? 0 : icon.width - width; width: step.bar; height: icon.height; color: icon.color }
        Shape {
            id: stepTri
            x: step.back ? step.bar : 0
            width: icon.width - step.bar; height: icon.height
            preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
            antialiasing: Theme.smooth
            ShapePath {
                strokeWidth: -1; fillColor: icon.color
                startX: step.back ? stepTri.width : 0; startY: 0
                PathLine { x: step.back ? 0 : stepTri.width; y: icon.height / 2 }
                PathLine { x: step.back ? stepTri.width : 0; y: icon.height }
                PathLine { x: step.back ? stepTri.width : 0; y: 0 }
            }
        }
    }

    // --- loop: a box going round, a head on the top edge (right) and the bottom (left) ---
    Item {
        id: loop
        visible: icon.name === "loop"
        anchors.fill: parent
        readonly property real head: Math.round(icon.s * 0.42)   // each head's length and half its height
        readonly property real inset: Math.round(icon.s * 0.16)  // the box sits inside the heads' height
        readonly property real boxTop: loop.inset
        readonly property real boxBottom: icon.height - loop.inset
        readonly property real mid: Math.round(icon.width / 2)
        // the box: left and right sides, and the top and bottom up to the heads
        Rectangle { x: 0; y: loop.boxTop; width: icon.t; height: loop.boxBottom - loop.boxTop; color: icon.color }
        Rectangle { x: icon.width - icon.t; y: loop.boxTop; width: icon.t; height: loop.boxBottom - loop.boxTop; color: icon.color }
        Rectangle { x: 0; y: loop.boxTop; width: loop.mid - loop.head / 2 + 1; height: icon.t; color: icon.color }
        Rectangle { x: loop.mid + loop.head / 2 - 1; y: loop.boxBottom - icon.t; width: icon.width - x; height: icon.t; color: icon.color }
        Repeater {
            model: 2
            Shape {
                id: loopHead
                required property int index
                readonly property bool onTop: index === 0
                x: loop.mid - loop.head / 2
                y: (onTop ? loop.boxTop : loop.boxBottom - icon.t) + icon.t / 2 - loop.head / 2 - 1
                width: loop.head; height: loop.head + 2
                preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
                antialiasing: Theme.smooth
                ShapePath {
                    strokeWidth: -1; fillColor: icon.color
                    startX: loopHead.onTop ? 0 : loopHead.width; startY: 0
                    PathLine { x: loopHead.onTop ? loopHead.width : 0; y: loopHead.height / 2 }
                    PathLine { x: loopHead.onTop ? 0 : loopHead.width; y: loopHead.height }
                    PathLine { x: loopHead.onTop ? 0 : loopHead.width; y: 0 }
                }
            }
        }
    }

    // --- bounce, once, hold: a shaft with heads (and hold's bar) ---------------------
    Item {
        id: shaft
        visible: icon.name === "bounce" || icon.name === "once" || icon.name === "hold"
        anchors.fill: parent
        readonly property real head: Math.round(icon.s * 0.5)
        readonly property real bar: icon.name === "hold" ? icon.t + Math.round(icon.s * 0.12) : 0   // hold: the bar and its gap
        readonly property real end: icon.width - shaft.bar   // where the right head's nose is
        Rectangle {
            x: icon.name === "bounce" ? shaft.head - 1 : 0
            y: Math.round((icon.height - icon.t) / 2)
            width: shaft.end - shaft.head + 1 - x; height: icon.t
            color: icon.color
        }
        Repeater {
            model: icon.name === "bounce" ? 2 : 1
            Shape {
                id: shaftHead
                required property int index
                readonly property bool pointsLeft: index === 1
                x: pointsLeft ? 0 : shaft.end - shaft.head
                width: shaft.head; height: icon.height
                preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
                antialiasing: Theme.smooth
                ShapePath {
                    strokeWidth: -1; fillColor: icon.color
                    startX: shaftHead.pointsLeft ? shaftHead.width : 0; startY: icon.height * 0.1
                    PathLine { x: shaftHead.pointsLeft ? 0 : shaftHead.width; y: icon.height / 2 }
                    PathLine { x: shaftHead.pointsLeft ? shaftHead.width : 0; y: icon.height * 0.9 }
                    PathLine { x: shaftHead.pointsLeft ? shaftHead.width : 0; y: icon.height * 0.1 }
                }
            }
        }
        Rectangle { visible: icon.name === "hold"; x: icon.width - icon.t; width: icon.t; height: icon.height; color: icon.color }
    }

    // --- animate: a ball moving right, two crescents trailing it (each cut by the next) --
    // Always smoothed: at a label's size, hard-edged circles crunch.
    Item {
        id: motion
        visible: icon.name === "animate"
        anchors.fill: parent
        readonly property real cy: icon.height / 2
        readonly property real gap: Math.max(1, icon.s * 0.1)
        // the ball, and the two behind it, smaller, each showing a crescent this thick
        readonly property real r3: icon.height / 2
        readonly property real c3: icon.width - r3
        readonly property real r2: r3 * 0.84
        readonly property real c2: c3 - r3 - gap + r2 * 0.36
        readonly property real r1: r3 * 0.68
        readonly property real c1: c2 - r2 - gap + r1 * 0.36
        Rectangle {
            x: motion.c3 - motion.r3; y: 0
            width: 2 * motion.r3; height: width
            radius: width / 2
            antialiasing: true
            color: icon.color
        }
        Repeater {
            // [the crescent's centre, radius] and the circle cutting it (the next one, plus the gap)
            model: [[motion.c2, motion.r2, motion.c3, motion.r3 + motion.gap],
                    [motion.c1, motion.r1, motion.c2, motion.r2 + motion.gap]]
            Shape {
                id: crescent
                required property var modelData
                readonly property real ca: modelData[0]
                readonly property real ra: modelData[1]
                readonly property real cb: modelData[2]
                readonly property real rb: modelData[3]
                // where the two circles cross, from the crescent's centre
                readonly property real dx: cb - ca
                readonly property real xi: (dx * dx + ra * ra - rb * rb) / (2 * dx)
                readonly property real yi: Math.sqrt(Math.max(0, ra * ra - xi * xi))
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                antialiasing: true
                ShapePath {
                    strokeWidth: -1; fillColor: icon.color
                    startX: crescent.ca + crescent.xi; startY: motion.cy - crescent.yi
                    // round its back, the long way
                    PathArc {
                        x: crescent.ca + crescent.xi; y: motion.cy + crescent.yi
                        radiusX: crescent.ra; radiusY: crescent.ra
                        useLargeArc: crescent.xi > 0
                        direction: PathArc.Counterclockwise
                    }
                    // and back up the inside, along the next circle
                    PathArc {
                        x: crescent.ca + crescent.xi; y: motion.cy - crescent.yi
                        radiusX: crescent.rb; radiusY: crescent.rb
                        direction: PathArc.Clockwise
                    }
                }
            }
        }
    }

    // --- pencil: tip at the bottom left, the body up to the right ----------------------
    Item {
        id: pencil
        visible: icon.name === "pencil"
        anchors.centerIn: parent
        readonly property real thick: Math.round(icon.s * 0.36)
        readonly property real tip: Math.round(icon.s * 0.4)
        width: Math.round(Math.hypot(icon.width, icon.height) * 0.92); height: thick
        rotation: -45
        // the point
        Shape {
            id: pencilTip
            width: pencil.tip; height: pencil.thick
            preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
            antialiasing: Theme.smooth
            ShapePath {
                strokeWidth: -1; fillColor: icon.color
                startX: 0; startY: pencilTip.height / 2
                PathLine { x: pencilTip.width; y: 0 }
                PathLine { x: pencilTip.width; y: pencilTip.height }
                PathLine { x: 0; y: pencilTip.height / 2 }
            }
        }
        // the body, a gap after the point
        Rectangle { x: pencil.tip + Math.max(1, Math.round(icon.s * 0.08)); width: pencil.width - x; height: pencil.thick; color: icon.color }
    }
}
