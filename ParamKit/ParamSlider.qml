import QtQuick
import "ParamMath.js" as PM

/// A labelled bar slider. The lime fill grows from origin to the value; at
/// its edge sit two arrows: click one to step by one (Shift: by ten), hold
/// it to repeat, or drag it to slide as usual. Click anywhere else on the
/// bar to jump there and drag. The value sits in a box under the edge;
/// click it to type a value. The bar spans from..to, but stepping and
/// typing may go past it, up to limitFrom..limitTo (no limit by default),
/// so a full bar can still be nudged. Double-click the bar, or the reset
/// mark by the label, to go back to defaultValue.
///
/// Like Qt's Slider: value is set by the user, moved() reports only user
/// changes, so bind value to your setting and write it back in onMoved.
Item {
    id: root

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property int decimals: PM.decimalsFor(stepSize)
    property string unit: ""
    //! Where the fill grows from: from by default, 0 for a centred range.
    property real origin: from
    property real limitFrom: -Infinity
    property real limitTo: Infinity
    property real defaultValue: NaN

    signal moved(real value)

    readonly property bool pressed: ma.pressed
    readonly property bool editing: box.editing

    implicitWidth: Theme.s(280)
    implicitHeight: head.height + track.height + box.height
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    //! Sets the value as the user would: snapped, limited, reported.
    function setValue(v) {
        v = PM.clamp(PM.snap(v, root.stepSize, root.from), root.limitFrom, root.limitTo)
        if (v !== root.value) { root.value = v; root.moved(v) }
    }
    function step(direction, big) { setValue(root.value + direction * root.stepSize * (big ? 10 : 1)) }
    function reset() { if (!isNaN(root.defaultValue)) setValue(root.defaultValue) }

    readonly property bool canDown: root.value > root.limitFrom
    readonly property bool canUp: root.value < root.limitTo
    readonly property bool isDefault: isNaN(root.defaultValue) || Math.abs(root.value - root.defaultValue) < root.stepSize / 2

    // The bar always leaves room on its right for an arrow that steps past
    // its end, so bars line up whatever their limits. An arrow past the
    // start draws in the margin to the left of the control.
    readonly property real reach: Theme.arrowW + 2 * Theme.arrowGap
    readonly property real gutterL: 0
    readonly property real gutterR: reach

    // Drawn from an eased copy of the value, so steps glide and drags don't lag.
    property real shown: value
    Behavior on shown { enabled: !ma.dragging; NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
    function fraction(v) { return root.to === root.from ? 0 : PM.clamp((v - root.from) / (root.to - root.from), 0, 1) }
    readonly property real edgeX: track.width * fraction(root.shown)
    readonly property real originX: track.width * fraction(root.origin)

    // --- label row -----------------------------------------------------------
    Item {
        id: head
        width: parent.width
        height: root.label.length ? title.implicitHeight + Theme.rowGap : 0
        visible: height > 0

        Text {
            id: title
            width: parent.width - resetMark.width - Theme.s(6)
            text: root.label
            elide: Text.ElideRight
            color: root.activeFocus ? Theme.text : Qt.darker(Theme.text, 1.04)
            font.family: Theme.family
            font.pixelSize: Theme.labelSize
        }
        Text {
            id: resetMark
            anchors.right: parent.right
            anchors.rightMargin: root.gutterR
            text: "↺"   // ↺
            color: resetHover.hovered ? Theme.accent : Theme.textFaint
            font.pixelSize: Theme.labelSize
            opacity: !root.isDefault && (hover.hovered || root.activeFocus) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.ease } }
            HoverHandler { id: resetHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { enabled: resetMark.opacity > 0; onTapped: root.reset() }
        }
    }

    // --- the bar -------------------------------------------------------------
    Rectangle {
        id: track
        x: root.gutterL
        y: head.height
        width: root.width - root.gutterL - root.gutterR
        height: Theme.trackHeight
        radius: Theme.radius
        color: hover.hovered && !ma.pressed ? Theme.wellHover : Theme.well
        Behavior on color { ColorAnimation { duration: Theme.quick } }

        // the keyboard focus ring
        Rectangle {
            anchors.fill: parent
            anchors.margins: -Theme.s(2)
            color: "transparent"
            border.width: 1
            border.color: Theme.accent
            opacity: root.activeFocus && !ma.focusedByMouse ? 0.6 : 0
            radius: Theme.radius
        }

        Rectangle {
            id: fill
            x: Math.min(root.edgeX, root.originX)
            width: Math.abs(root.edgeX - root.originX)
            height: parent.height
            color: Theme.accent
            radius: Theme.radius
        }

        // the origin of a centred range
        Rectangle {
            visible: root.origin > root.from && root.origin < root.to
            x: Math.round(root.originX)
            width: 1
            height: parent.height
            color: root.edgeX === root.originX ? Theme.accent : Theme.page
            opacity: 0.7
        }

        // value past the bar's ends: a notch on the end it went past
        Rectangle {
            visible: root.value > root.to || root.value < root.from
            x: root.value > root.to ? parent.width - width : 0
            width: Theme.s(3); height: parent.height
            color: Theme.accentInk
            opacity: 0.55
        }

        ParamArrow {
            id: down
            direction: Qt.LeftArrow
            visible: root.canDown && root.enabled
            x: root.edgeX - Theme.arrowGap - width
            anchors.verticalCenter: parent.verticalCenter
            readonly property bool onFill: root.edgeX > root.originX && x >= 0
            readonly property bool hot: ma.hoverZone === -1 || (ma.pressed && ma.pressZone === -1)
            color: onFill ? (hot ? Theme.accentInk : Theme.accentDim)
                          : (hot ? Theme.arrowHot : Theme.arrow)
            scale: ma.pressed && ma.pressZone === -1 && !ma.dragging ? 0.85 : 1
        }
        ParamArrow {
            id: up
            direction: Qt.RightArrow
            visible: root.canUp && root.enabled
            x: root.edgeX + Theme.arrowGap
            anchors.verticalCenter: parent.verticalCenter
            readonly property bool onFill: root.edgeX < root.originX
            readonly property bool hot: ma.hoverZone === 1 || (ma.pressed && ma.pressZone === 1)
            color: onFill ? (hot ? Theme.accentInk : Theme.accentDim)
                          : (hot ? Theme.arrowHot : Theme.arrow)
            scale: ma.pressed && ma.pressZone === 1 && !ma.dragging ? 0.85 : 1
        }
    }

    HoverHandler { id: hover }

    MouseArea {
        id: ma
        x: -root.reach; y: track.y
        width: root.width + root.reach; height: track.height
        enabled: root.enabled
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton

        property int pressZone: 0
        property bool dragging: false
        property bool repeated: false
        property bool focusedByMouse: false
        property real startX: 0
        property real startValue: 0
        property bool fine: false
        readonly property int hoverZone: containsMouse && !pressed ? zoneAt(mouseX) : 0

        cursorShape: dragging ? Qt.SizeHorCursor
                   : hoverZone !== 0 ? Qt.PointingHandCursor
                   : Qt.ArrowCursor

        //! -1 over the down arrow, +1 over the up arrow, 0 over the bar.
        function zoneAt(mx) {
            mx += ma.x
            const ex = track.x + root.edgeX
            const r = root.reach + Theme.s(3)
            if (down.visible && mx >= ex - r && mx < ex) return -1
            if (up.visible && mx >= ex && mx <= ex + r) return 1
            return 0
        }
        function valueAt(mx) {
            return root.from + PM.clamp((mx + ma.x - track.x) / track.width, 0, 1) * (root.to - root.from)
        }
        function rebase(mx) { startX = mx; startValue = root.value }

        onPressed: m => {
            focusedByMouse = true
            root.forceActiveFocus(Qt.MouseFocusReason)
            pressZone = zoneAt(m.x)
            repeated = false
            fine = m.modifiers & Qt.ShiftModifier
            if (pressZone === 0) {
                dragging = true
                root.setValue(valueAt(m.x))
            } else {
                dragging = false
                holdTimer.restart()
            }
            rebase(m.x)
        }
        onPositionChanged: m => {
            if (!pressed) return
            const nowFine = !!(m.modifiers & Qt.ShiftModifier)
            if (!dragging && Math.abs(m.x - startX) > Theme.s(4)) {
                dragging = true
                holdTimer.stop(); repeatTimer.stop()
                rebase(m.x)
            }
            if (!dragging) return
            if (nowFine !== fine) { fine = nowFine; rebase(m.x) }
            const dv = (m.x - startX) / track.width * (root.to - root.from) * (fine ? 0.1 : 1)
            // A drag stays on the bar, unless it started past an end.
            root.setValue(PM.clamp(startValue + dv, Math.min(root.from, startValue), Math.max(root.to, startValue)))
        }
        onReleased: m => {
            holdTimer.stop(); repeatTimer.stop()
            if (!dragging && !repeated && pressZone !== 0)
                root.step(pressZone, m.modifiers & Qt.ShiftModifier)
            dragging = false
        }
        onCanceled: { holdTimer.stop(); repeatTimer.stop(); dragging = false }
        onDoubleClicked: m => { if (zoneAt(m.x) === 0) root.reset() }

        Timer { id: holdTimer; interval: 380; onTriggered: { ma.repeated = true; root.step(ma.pressZone, ma.fine); repeatTimer.start() } }
        Timer { id: repeatTimer; interval: 55; repeat: true; onTriggered: root.step(ma.pressZone, ma.fine) }
    }

    onActiveFocusChanged: if (!activeFocus) ma.focusedByMouse = false

    Keys.onPressed: e => {
        const big = e.modifiers & Qt.ShiftModifier
        ma.focusedByMouse = false
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

    // --- the value -----------------------------------------------------------
    ParamValueBox {
        id: box
        y: track.y + track.height
        x: PM.clamp(track.x + root.edgeX, 0, Math.max(0, root.width - width))
        value: root.value
        decimals: root.decimals
        unit: root.unit
        interactive: root.enabled
        onSubmitted: v => root.setValue(v)
        onStepped: (direction, big) => root.step(direction, big)
    }
}
