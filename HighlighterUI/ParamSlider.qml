import QtQuick
import "ParamMath.js" as PM

/// A labelled bar slider. The lime fill grows from origin to the value and
/// ends in a darker line; beside the line sit two arrows: click one to step
/// by one (Shift: by ten), hold it to repeat, or drag it to slide as usual.
/// Click anywhere else on the bar to jump there and drag. The value sits in
/// a box under the edge; press it to type a value. The bar spans from..to,
/// but stepping and typing may go past it, up to limitFrom..limitTo (no
/// limit by default), so a full bar can still be nudged. Double-click the
/// bar, or the reset mark by the label, to go back to defaultValue.
///
/// Like Qt's Slider: value is set by the user, moved() reports only user
/// changes, so bind value to your setting and write it back in onMoved.
Item {
    id: root

    //! The accent it draws in: the nearest one declared around it (see Theme).
    readonly property color tint: Theme.accentAt(root, Window.window)

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
    //! What the panel remembers this slider by (whether it was maximised).
    //! Give it the setting's key; the label is used if not.
    property string key: label
    //! Whether it has its own min / max button (off when it is part of
    //! another control, as in a minimised ParamXY).
    property bool sizeToggle: true
    //! Minimised: a thin bar. Sliders start minimised, unless the user
    //! maximised this one before; the min / max button by the label flips it.
    //! An illustrated slider starts maximised, so its picture shows; the
    //! user's own choice either way is remembered.
    property bool compact: PanelMemory.isMinimised(key) ? true
                         : PanelMemory.isMaximised(key) ? false
                         : Theme.slidersStartMinimised && root.pattern === null && root.illustration === null

    //! An illustration above the bar, shown when maximised, for settings a
    //! picture explains (see ParamFrames): a dot matrix, pattern(col, row, t),
    //! or a custom drawing, illustration (a ParamFrame Component). frames
    //! pictures across the range; click one to jump to it.
    property var pattern: null
    property Component illustration: null
    property int frames: 5
    property int cols: 20
    property int rows: 12
    readonly property bool illustrated: (root.pattern !== null || root.illustration !== null) && !root.compact

    signal moved(real value)

    readonly property bool pressed: ma.pressed
    readonly property bool editing: box.editing

    implicitWidth: Theme.s(320)
    implicitHeight: head.height + pictures.height + track.height + box.height
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    //! Sets the value as the user would: snapped, limited, reported.
    function setValue(v) {
        v = PM.clamp(PM.snap(v, root.stepSize, root.from), root.limitFrom, root.limitTo)
        if (v !== root.value) { root.value = v; root.moved(v) }
    }
    function step(direction, big) { setValue(root.value + direction * root.stepSize * (big ? 10 : 1)) }
    function reset() { if (!isNaN(root.defaultValue)) setValue(root.defaultValue) }
    //! Makes the value the new default (what a panel's "Save as defaults" does).
    function saveDefault() { root.defaultValue = root.value }

    readonly property bool canDown: root.value > root.limitFrom
    readonly property bool canUp: root.value < root.limitTo
    readonly property bool isDefault: isNaN(root.defaultValue) || Math.abs(root.value - root.defaultValue) < root.stepSize / 2

    // This slider's sizes, minimised or not.
    // With its display showing, the bar is thin (its picture does the
    // explaining); the label and value keep their size.
    readonly property var illustratedBar: ({ track: 20, edge: 3, arrowW: 7, arrowH: 10, gap: 3 })
    function sz(key) {
        if (root.illustrated && root.illustratedBar[key] !== undefined) return Theme.s(root.illustratedBar[key])
        return Theme.sliderSize(key, root.compact)
    }
    readonly property int arrowW: sz("arrowW")
    readonly property int arrowH: sz("arrowH")
    readonly property int gap: sz("gap")

    // The bar leaves room on its right for the up arrow to sit past a full
    // bar, so every bar lines up whatever its limits; the value box stays
    // inside the slider's width.
    readonly property real gutterR: Theme.sliderSize("arrowW", false) + 2 * Theme.sliderSize("gap", false)

    // Drawn from an eased copy of the value, so steps glide and drags don't lag.
    property real shown: value
    Behavior on shown { enabled: !ma.dragging; NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
    function fraction(v) { return root.to === root.from ? 0 : PM.clamp((v - root.from) / (root.to - root.from), 0, 1) }
    readonly property real edgeX: track.width * fraction(root.shown)
    readonly property real originX: track.width * fraction(root.origin)
    readonly property real fillX: Math.min(edgeX, originX)
    readonly property real fillW: Math.abs(edgeX - originX)

    // --- where the arrows go -------------------------------------------------
    // (Maximised only.) Always either side of the edge line: down on the fill, up on the well
    // (swapped sides for a fill growing left). An arrow with no room on its
    // side jumps out past the bar's end, clear of it. An arrow that can't step (the
    // value is at its limit) stays, greyed out.
    readonly property real lineW: Math.min(sz("edge"), fillW)
    readonly property bool growsRight: edgeX >= originX
    readonly property var arrowX: {
        const w = arrowW, g = gap, e = edgeX
        const lineL = growsRight ? lineW : 0, lineR = growsRight ? 0 : lineW
        let dx = e - lineL - g - w, ux = e + lineR + g
        // No room on the bar: jump clear of it rather than overlap its end.
        if (dx < 0) dx = -g - w
        if (ux + w > track.width) ux = track.width + g
        return { down: dx, up: ux }
    }
    function onFill(x) { const c = x + arrowW / 2; return c > fillX && c < fillX + fillW }

    // --- label row -----------------------------------------------------------
    Item {
        id: head
        width: parent.width
        height: root.label.length ? title.implicitHeight + root.sz("row") : 0
        visible: height > 0

        Text {
            id: title
            width: parent.width - root.gutterR - sizeMark.width - resetMark.width - Theme.s(12)
            text: root.label
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.family
            font.pixelSize: root.sz("title")
        }
        Text {
            id: resetMark
            anchors.right: root.sizeToggle ? sizeMark.left : parent.right
            anchors.rightMargin: root.sizeToggle ? Theme.s(8) : root.gutterR
            anchors.verticalCenter: sizeMark.verticalCenter
            text: "↺"   // ↺
            color: resetHover.hovered ? root.tint : Theme.textFaint
            font.family: Theme.family
            font.pixelSize: root.sz("title")
            opacity: !root.isDefault && (hover.hovered || root.activeFocus) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.ease } }
            HoverHandler { id: resetHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { enabled: resetMark.opacity > 0; onTapped: root.reset() }
        }
        // min / max, like the reset mark only there while hovered or focused
        ParamSizeMark {
            id: sizeMark
            objectName: "sizeMark"
            anchors.right: parent.right
            anchors.rightMargin: root.gutterR
            anchors.verticalCenter: title.verticalCenter
            visible: root.sizeToggle
            compact: root.compact
            shown: hover.hovered || root.activeFocus
            tint: root.tint
            onToggled: {
                root.compact = !root.compact
                PanelMemory.setMaximised(root.key, !root.compact)
            }
        }
    }

    // --- the illustration, maximised only -------------------------------------
    Item {
        id: pictures
        y: head.height
        width: root.width - root.gutterR
        height: root.illustrated ? strip.height + Theme.s(4) : 0
        visible: root.illustrated
        ParamFrames {
            id: strip
            width: parent.width
            frames: root.frames
            position: root.fraction(root.shown)
            pattern: root.pattern
            illustration: root.illustration
            cols: root.cols
            rows: root.rows
            // the value on the display, as many places as the range needs
            readout: root.value.toFixed(root.decimals)
            readoutDigits: Math.max(String(Math.abs(root.from).toFixed(root.decimals)).replace(".", "").length,
                                    String(Math.abs(root.to).toFixed(root.decimals)).replace(".", "").length,
                                    String(Math.abs(root.value).toFixed(root.decimals)).replace(".", "").length) + (root.from < 0 ? 1 : 0)
            unit: root.unit
            onPicked: t => { root.forceActiveFocus(); root.setValue(root.from + t * (root.to - root.from)) }
        }
    }

    // --- the bar -------------------------------------------------------------
    Rectangle {
        id: track
        y: head.height + pictures.height
        width: root.width - root.gutterR
        height: root.sz("track")
        radius: Theme.radius
        color: hover.hovered && !ma.pressed ? Theme.wellHover : Theme.well
        Behavior on color { ColorAnimation { duration: Theme.quick } }

        // the keyboard focus ring
        Rectangle {
            anchors.fill: parent
            anchors.margins: -Theme.s(2)
            color: "transparent"
            border.width: 1
            border.color: root.tint
            opacity: root.activeFocus && !ma.focusedByMouse && !box.editing ? 0.6 : 0
            radius: Theme.radius
        }

        Rectangle {
            id: fill
            x: root.fillX
            width: root.fillW
            height: parent.height
            color: Theme.litOf(root.tint)
            radius: Theme.radius
            // hardware: lit, like a backlit bar
            ParamGlow { anchors.fill: parent; z: -1; color: root.tint; strength: root.fillW > 0 && root.enabled ? 0.5 : 0 }
        }
        // the darker line along the fill's moving edge
        Rectangle {
            visible: root.lineW > 0
            x: root.growsRight ? root.edgeX - root.lineW : root.edgeX
            width: root.lineW
            height: parent.height
            color: Theme.edgeOf(root.tint)
        }
        // the fill catches the light, in the classic skin
        Image {
            visible: Theme.classic && root.fillW > 0
            x: root.fillX; width: root.fillW; height: parent.height
            source: "textures/sheen.png"
            smooth: true
            opacity: 0.3
        }
        // the bar sits in a channel, in the classic skin
        ParamBevel { anchors.fill: parent; visible: Theme.classic; inset: true; dark: 0.55; light: 0.14 }

        // the saved default, dotted, while the value is away from it
        Item {
            id: defaultMark
            objectName: "defaultMark"
            readonly property real at: root.defaultValue > root.to ? track.width
                                     : track.width * root.fraction(root.defaultValue)
            readonly property bool overFill: at > root.fillX && at < root.fillX + root.fillW
            x: Math.round(Math.min(at, track.width - width))
            width: Theme.s(2)
            height: parent.height
            // Hidden where it would sit on the fill's edge line (the value is
            // a hair from the default anyway).
            visible: !root.isDefault && Math.abs(x + width / 2 - root.edgeX) > width + root.lineW
            // Where it crosses an arrow it breaks, leaving a gap round it.
            readonly property real clear: Theme.s(2)
            function crosses(arrow) {
                return arrow.visible && x + width > arrow.x - clear && x < arrow.x + arrow.width + clear
            }
            readonly property bool broken: crosses(down) || crosses(up)
            readonly property real gapTop: (height - root.arrowH) / 2 - clear
            readonly property real gapBottom: (height + root.arrowH) / 2 + clear
            Repeater {
                model: Math.ceil(track.height / Theme.s(6))
                Rectangle {
                    required property int index
                    y: index * Theme.s(6)
                    width: defaultMark.width; height: Theme.s(3)
                    visible: !(defaultMark.broken && y + height > defaultMark.gapTop && y < defaultMark.gapBottom)
                    color: defaultMark.overFill ? Theme.inkOf(root.tint) : Theme.text
                    opacity: defaultMark.overFill ? 0.55 : 0.6
                }
            }
        }

        // the origin of a centred range
        Rectangle {
            visible: root.origin > root.from && root.origin < root.to
            x: Math.round(root.originX)
            width: 1
            height: parent.height
            color: root.fillW < 1 ? root.tint : Theme.page
            opacity: 0.7
        }

        ParamArrow {
            id: down
            objectName: "downArrow"
            direction: Qt.LeftArrow
            visible: root.enabled && !root.compact   // a minimised slider has no arrows
            opacity: root.canDown ? 1 : 0.3
            x: root.arrowX.down
            width: root.arrowW; height: root.arrowH
            anchors.verticalCenter: parent.verticalCenter
            readonly property bool hot: root.canDown && (ma.hoverZone === -1 || (ma.pressed && ma.pressZone === -1))
            color: root.onFill(x) ? (hot ? Theme.inkOf(root.tint) : Theme.dimOf(root.tint))
                                  : (hot ? Theme.arrowHot : Theme.arrow)
            scale: hot && ma.pressed && !ma.dragging ? 0.85 : 1
        }
        ParamArrow {
            id: up
            objectName: "upArrow"
            direction: Qt.RightArrow
            visible: root.enabled && !root.compact   // a minimised slider has no arrows
            opacity: root.canUp ? 1 : 0.3
            x: root.arrowX.up
            width: root.arrowW; height: root.arrowH
            anchors.verticalCenter: parent.verticalCenter
            readonly property bool hot: root.canUp && (ma.hoverZone === 1 || (ma.pressed && ma.pressZone === 1))
            color: root.onFill(x) ? (hot ? Theme.inkOf(root.tint) : Theme.dimOf(root.tint))
                                  : (hot ? Theme.arrowHot : Theme.arrow)
            scale: hot && ma.pressed && !ma.dragging ? 0.85 : 1
        }
    }

    HoverHandler { id: hover }

    MouseArea {
        id: ma
        // reaches left of the bar too, for a down arrow hanging past its start
        x: -(root.arrowW + root.gap + Theme.s(6))
        // a thin bar still gets a grabbable strip, at least 20px tall
        readonly property real grow: Math.max(0, (Theme.s(20) - track.height) / 2)
        y: track.y - grow
        width: root.width - x; height: track.height + 2 * grow
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
                   : (hoverZone === -1 && root.canDown) || (hoverZone === 1 && root.canUp) ? Qt.PointingHandCursor
                   : Qt.ArrowCursor

        //! -1 over the down arrow, +1 over the up arrow, 0 over the bar.
        //! Each arrow's zone is generous; where they meet, it splits halfway.
        function zoneAt(mx) {
            mx += ma.x
            const w = root.arrowW, r = Theme.s(6)
            const d = root.arrowX.down, u = root.arrowX.up
            const dVis = down.visible, uVis = up.visible
            let dLo = d - r, dHi = d + w + r, uLo = u - r, uHi = u + w + r
            if (dVis && uVis) {
                const mid = d < u ? (d + w + u) / 2 : (u + w + d) / 2
                if (d < u) { dHi = Math.min(dHi, mid); uLo = Math.max(uLo, mid) }
                else { uHi = Math.min(uHi, mid); dLo = Math.max(dLo, mid) }
            }
            if (dVis && mx >= dLo && mx < dHi) return -1
            if (uVis && mx >= uLo && mx <= uHi) return 1
            return 0
        }
        function valueAt(mx) {
            return root.from + PM.clamp((mx + ma.x) / track.width, 0, 1) * (root.to - root.from)
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
    // Under the edge, starting at it; flipped to end at it when it would run
    // off the right.
    ParamValueBox {
        id: box
        y: track.y + track.height
        x: {
            const e = track.x + root.edgeX
            return e + width <= root.width ? e : Math.max(0, Math.min(e, root.width) - width)
        }
        value: root.value
        decimals: root.decimals
        unit: root.unit
        interactive: root.enabled
        boxHeight: root.sz("box")
        fontSize: root.sz("value")
        onSubmitted: v => root.setValue(v)
        onStepped: (direction, big) => root.step(direction, big)
        // Give the keyboard back to the slider, without a focus ring.
        onFinished: { ma.focusedByMouse = true; root.forceActiveFocus(Qt.MouseFocusReason) }
    }
}
