import QtQuick
import QtQuick.Shapes
import "ParamMath.js" as PM

/// A labelled rotary knob: drag up or right to raise it (Shift: finely),
/// double-click to go back to defaultValue. Its value box sits underneath
/// between two step arrows, and works as the slider's does: click to type,
/// arrows to step by one (Shift: ten), past from..to up to limitFrom..limitTo.
Item {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentIn(Window.window)

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property int decimals: PM.decimalsFor(stepSize)
    property string unit: ""
    property real origin: from
    property real limitFrom: -Infinity
    property real limitTo: Infinity
    property real defaultValue: NaN
    //! Tick marks around the dial, 0 for none.
    property int ticks: 11
    property int diameter: Theme.knobSize

    signal moved(real value)

    readonly property bool pressed: drag.pressed

    implicitWidth: Math.max(Theme.s(96), diameter + Theme.s(24), title.implicitWidth, valueRow.implicitWidth + Theme.s(8))
    implicitHeight: title.height + Theme.rowGap + dial.height + Theme.s(6) + valueRow.height
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    function setValue(v) {
        v = PM.clamp(PM.snap(v, root.stepSize, root.from), root.limitFrom, root.limitTo)
        if (v !== root.value) { root.value = v; root.moved(v) }
    }
    function step(direction, big) { setValue(root.value + direction * root.stepSize * (big ? 10 : 1)) }
    function reset() { if (!isNaN(root.defaultValue)) setValue(root.defaultValue) }
    function fraction(v) { return root.to === root.from ? 0 : PM.clamp((v - root.from) / (root.to - root.from), 0, 1) }

    property real shown: value
    Behavior on shown { enabled: !drag.pressed; NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }

    Text {
        id: title
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.label
        elide: Text.ElideRight
        color: Theme.text
        font.family: Theme.family
        font.pixelSize: Theme.titleSize
        height: text.length ? implicitHeight : 0
    }

    Item {
        id: dial
        anchors.horizontalCenter: parent.horizontalCenter
        y: title.height + Theme.rowGap
        width: root.diameter + Theme.s(16)
        height: width

        // Drawn as shapes, not a Canvas, so Theme.smooth can turn the
        // antialiasing off (a Canvas always smooths).
        Shape {
            id: face
            anchors.fill: parent
            preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
            antialiasing: Theme.smooth
            readonly property real cx: width / 2
            readonly property real cy: height / 2
            readonly property real outer: root.diameter / 2
            readonly property real ring: Theme.s(4)
            readonly property real fr: outer - ring - Theme.s(3)          // the face's radius
            readonly property real fo: root.fraction(root.origin)
            readonly property real fv: root.fraction(root.shown)
            function deg(f) { return 135 + 270 * f }
            function rad(f) { return deg(f) * Math.PI / 180 }
            readonly property bool hot: drag.containsMouse || drag.pressed
            readonly property var tickLines: {
                const out = []
                for (let i = 0; i < root.ticks && root.ticks > 1; ++i) {
                    const a = rad(i / (root.ticks - 1))
                    const r1 = outer + Theme.s(3), r2 = outer + Theme.s(i % 5 === 0 ? 7 : 5)
                    out.push([Qt.point(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1),
                              Qt.point(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2)])
                }
                return out
            }

            ShapePath {   // ticks
                strokeColor: Theme.textFaint; strokeWidth: 1; fillColor: "transparent"
                PathMultiline { paths: face.tickLines }
            }
            ShapePath {   // the track
                strokeColor: Theme.well; strokeWidth: face.ring; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: face.cx; centerY: face.cy; radiusX: face.outer - face.ring / 2; radiusY: radiusX; startAngle: 135; sweepAngle: 270 }
            }
            ShapePath {   // the value along it
                strokeColor: face.fo === face.fv ? "transparent" : root.tint
                strokeWidth: face.ring; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                PathAngleArc { centerX: face.cx; centerY: face.cy; radiusX: face.outer - face.ring / 2; radiusY: radiusX
                               startAngle: face.deg(Math.min(face.fo, face.fv)); sweepAngle: 270 * Math.abs(face.fv - face.fo) }
            }
            ShapePath {   // the face
                strokeColor: root.activeFocus && !drag.focusedByMouse ? root.tint : "transparent"
                strokeWidth: 1
                fillColor: Theme.classic ? "transparent" : face.hot ? Theme.sunkenHover : Theme.sunken
                PathAngleArc { centerX: face.cx; centerY: face.cy; radiusX: face.fr; radiusY: face.fr; startAngle: 0; sweepAngle: 360 }
            }
            ShapePath {   // the pointer: a dot near the rim (flat look)
                strokeColor: "transparent"; fillColor: Theme.classic ? "transparent" : root.tint
                PathAngleArc {
                    readonly property real pr: face.fr - Theme.s(8)
                    centerX: face.cx + Math.cos(face.rad(face.fv)) * pr
                    centerY: face.cy + Math.sin(face.rad(face.fv)) * pr
                    radiusX: Theme.s(4); radiusY: Theme.s(4); startAngle: 0; sweepAngle: 360
                }
            }
            ShapePath {   // past an end: a dot beyond it
                strokeColor: "transparent"
                fillColor: root.value > root.to || root.value < root.from ? root.tint : "transparent"
                PathAngleArc {
                    readonly property real a: face.rad(root.value > root.to ? 1 : 0)
                    centerX: face.cx + Math.cos(a) * (face.outer + Theme.s(6))
                    centerY: face.cy + Math.sin(a) * (face.outer + Theme.s(6))
                    radiusX: Theme.s(3); radiusY: Theme.s(3); startAngle: 0; sweepAngle: 360
                }
            }
        }

        // classic: the rendered glossy knob (tools/render_assets.py), the
        // face's size, with the pointer drawn over it so it turns while the
        // light stays put
        Image {
            id: capImage
            visible: Theme.classic
            // the dome's edge is 0.86 of the sprite's half-width
            readonly property real edge: 0.86
            readonly property real skirt: face.fr
            width: Math.round(2 * skirt / edge); height: width
            x: Math.round(face.cx - width / 2); y: Math.round(face.cy - height / 2)
            source: "textures/knob_classic.png"
            sourceSize: Qt.size(256, 256)
            smooth: true
            mipmap: true
            opacity: face.hot ? 1 : 0.94
        }
        Shape {
            id: pointer
            anchors.fill: face
            visible: Theme.classic
            preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
            antialiasing: Theme.smooth
            // the dome's top is 0.80 of the sprite
            readonly property real capR: capImage.width / 2 * 0.80
            readonly property real a: face.rad(face.fv)
            ShapePath {   // the pointer: an accent line across the cap, from near its middle to its rim
                strokeColor: "#f2f6f8"   // a white line, as on the era's knobs
                strokeWidth: Math.max(2, Theme.s(2)); fillColor: "transparent"; capStyle: ShapePath.FlatCap
                startX: face.cx + Math.cos(pointer.a) * pointer.capR * 0.25
                startY: face.cy + Math.sin(pointer.a) * pointer.capR * 0.25
                PathLine { x: face.cx + Math.cos(pointer.a) * (pointer.capR - 1); y: face.cy + Math.sin(pointer.a) * (pointer.capR - 1) }
            }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            enabled: root.enabled
            hoverEnabled: true
            preventStealing: true
            cursorShape: pressed ? Qt.BlankCursor : Qt.SizeVerCursor
            property real lastX: 0
            property real lastY: 0
            property real exact: 0
            property bool focusedByMouse: false
            onPressed: m => {
                focusedByMouse = true
                root.forceActiveFocus(Qt.MouseFocusReason)
                lastX = m.x; lastY = m.y; exact = root.value
            }
            onPositionChanged: m => {
                if (!pressed) return
                const d = (m.x - lastX) - (m.y - lastY)
                lastX = m.x; lastY = m.y
                const perPx = (root.to - root.from) / Theme.s(220) * (m.modifiers & Qt.ShiftModifier ? 0.1 : 1)
                // Keep the unsnapped value, so slow drags on coarse steps still move.
                exact = PM.clamp(exact + d * perPx, Math.min(root.from, exact), Math.max(root.to, exact))
                root.setValue(exact)
            }
            onDoubleClicked: root.reset()
        }
    }

    onActiveFocusChanged: if (!activeFocus) drag.focusedByMouse = false

    Keys.onPressed: e => {
        const big = e.modifiers & Qt.ShiftModifier
        drag.focusedByMouse = false
        switch (e.key) {
        case Qt.Key_Left: case Qt.Key_Down: root.step(-1, big); break
        case Qt.Key_Right: case Qt.Key_Up: root.step(+1, big); break
        case Qt.Key_PageDown: root.step(-1, true); break
        case Qt.Key_PageUp: root.step(+1, true); break
        case Qt.Key_Home: root.setValue(root.from); break
        case Qt.Key_End: root.setValue(root.to); break
        case Qt.Key_Return: case Qt.Key_Enter: box.begin(); break
        case Qt.Key_Backspace: case Qt.Key_Delete: root.reset(); break
        default: return
        }
        e.accepted = true
    }

    Row {
        id: valueRow
        anchors.horizontalCenter: parent.horizontalCenter
        y: dial.y + dial.height + Theme.s(6) - Theme.s(14)
        spacing: Theme.s(4)
        height: box.height

        StepArrow { direction: Qt.LeftArrow; active: root.value > root.limitFrom; onStep: big => root.step(-1, big) }
        ParamValueBox {
            id: box
            value: root.value
            decimals: root.decimals
            unit: root.unit
            align: Text.AlignHCenter
            interactive: root.enabled
            onSubmitted: v => root.setValue(v)
            onStepped: (direction, big) => root.step(direction, big)
            onFinished: { drag.focusedByMouse = true; root.forceActiveFocus(Qt.MouseFocusReason) }
        }
        StepArrow { direction: Qt.RightArrow; active: root.value < root.limitTo; onStep: big => root.step(+1, big) }
    }

    //! A clickable step arrow that repeats while held.
    component StepArrow: Item {
        id: sa
        property int direction: Qt.RightArrow
        property bool active: true
        signal step(bool big)
        width: Theme.arrowW + Theme.s(6)
        height: Theme.boxHeight
        ParamArrow {
            anchors.centerIn: parent
            direction: sa.direction
            opacity: sa.active && root.enabled ? 1 : 0.3
            color: area.pressed ? Theme.accentIn(Window.window) : area.containsMouse ? Theme.arrowHot : Theme.arrow
            scale: area.pressed ? 0.85 : 1
        }
        MouseArea {
            id: area
            anchors.fill: parent
            enabled: sa.active && root.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            property bool big: false
            property bool repeated: false
            onPressed: m => { big = m.modifiers & Qt.ShiftModifier; repeated = false; hold.restart() }
            onReleased: { hold.stop(); rep.stop(); if (!repeated && containsMouse) sa.step(big) }
            onCanceled: { hold.stop(); rep.stop() }
            Timer { id: hold; interval: 380; onTriggered: { area.repeated = true; sa.step(area.big); rep.start() } }
            Timer { id: rep; interval: 55; repeat: true; onTriggered: sa.step(area.big) }
        }
    }
}
