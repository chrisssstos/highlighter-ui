import QtQuick
import "ParamMath.js" as PM

/// A labelled rotary knob: drag up or right to raise it (Shift: finely),
/// double-click to go back to defaultValue. Its value box sits underneath
/// between two step arrows, and works as the slider's does: click to type,
/// arrows to step by one (Shift: ten), past from..to up to limitFrom..limitTo.
Item {
    id: root

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
    onShownChanged: face.requestPaint()

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

        Canvas {
            id: face
            anchors.fill: parent
            antialiasing: true
            renderStrategy: Canvas.Cooperative
            property bool hot: drag.containsMouse || drag.pressed
            onHotChanged: requestPaint()
            Component.onCompleted: requestPaint()
            Connections { target: Theme; function onAccentChanged() { face.requestPaint() } function onScaleChanged() { face.requestPaint() } function onCompactChanged() { face.requestPaint() } }
            Connections { target: root; function onFromChanged() { face.requestPaint() } function onToChanged() { face.requestPaint() } function onDiameterChanged() { face.requestPaint() } function onEnabledChanged() { face.requestPaint() } }

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const cx = width / 2, cy = height / 2
                const R = root.diameter / 2
                const a0 = Math.PI * 0.75, sweep = Math.PI * 1.5
                const at = f => a0 + sweep * f
                const ring = Theme.s(4)

                // ticks
                if (root.ticks > 1) {
                    ctx.strokeStyle = Theme.textFaint
                    ctx.lineWidth = 1
                    for (let i = 0; i < root.ticks; ++i) {
                        const a = at(i / (root.ticks - 1))
                        const r1 = R + Theme.s(3), r2 = R + Theme.s(i % 5 === 0 ? 7 : 5)
                        ctx.beginPath()
                        ctx.moveTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1)
                        ctx.lineTo(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2)
                        ctx.stroke()
                    }
                }
                // the track, then the value along it
                ctx.lineCap = "butt"
                ctx.lineWidth = ring
                ctx.strokeStyle = Theme.well
                ctx.beginPath(); ctx.arc(cx, cy, R - ring / 2, a0, a0 + sweep, false); ctx.stroke()
                const fo = root.fraction(root.origin), fv = root.fraction(root.shown)
                if (fo !== fv) {
                    ctx.strokeStyle = Theme.accent
                    ctx.beginPath(); ctx.arc(cx, cy, R - ring / 2, at(Math.min(fo, fv)), at(Math.max(fo, fv)), false); ctx.stroke()
                }
                // the face
                const fr = R - ring - Theme.s(3)
                ctx.fillStyle = hot ? Theme.sunkenHover : Theme.sunken
                ctx.beginPath(); ctx.arc(cx, cy, fr, 0, Math.PI * 2); ctx.fill()
                ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.07)
                ctx.lineWidth = 1
                ctx.beginPath(); ctx.arc(cx, cy, fr - 0.5, Math.PI * 1.1, Math.PI * 1.9); ctx.stroke()
                // the pointer: a dot near the rim
                const a = at(fv), pr = fr - Theme.s(8)
                ctx.fillStyle = Theme.accent
                ctx.beginPath(); ctx.arc(cx + Math.cos(a) * pr, cy + Math.sin(a) * pr, Theme.s(3.5), 0, Math.PI * 2); ctx.fill()
                // past an end: a mark beyond it
                if (root.value > root.to || root.value < root.from) {
                    const ae = root.value > root.to ? a0 + sweep : a0
                    ctx.fillStyle = Theme.accent
                    ctx.beginPath(); ctx.arc(cx + Math.cos(ae) * (R + Theme.s(6)), cy + Math.sin(ae) * (R + Theme.s(6)), Theme.s(2.5), 0, Math.PI * 2); ctx.fill()
                }
                // keyboard focus
                if (root.activeFocus && !drag.focusedByMouse) {
                    ctx.strokeStyle = Theme.accent
                    ctx.globalAlpha = 0.6
                    ctx.beginPath(); ctx.arc(cx, cy, fr + 1.5, 0, Math.PI * 2); ctx.stroke()
                }
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

    onActiveFocusChanged: { if (!activeFocus) drag.focusedByMouse = false; face.requestPaint() }

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
        face.requestPaint()
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
            color: area.pressed ? Theme.accent : area.containsMouse ? Theme.arrowHot : Theme.arrow
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
