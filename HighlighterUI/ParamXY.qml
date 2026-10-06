import QtQuick
import "ParamMath.js" as PM

/// A grid with a dot, for placing something on a canvas: click or drag to
/// put the dot there (Shift: finely, Ctrl: snap to the grid), arrow keys
/// nudge it (Shift: by ten). The pad takes the canvas's shape (xFrom..xTo by
/// yFrom..yTo, or aspect). Its x and y sit in value boxes underneath, to
/// type. footprintWidth/Height outline the element's size round the dot;
/// ghosts mark where other elements sit. Away from the default, a dotted
/// square marks it; double-click or the reset mark goes back.
///
/// Minimised it is the same grid as a thumbnail, its x and y boxes beside
/// it (still draggable and typeable); maximised, the full grid, the boxes
/// under it. The − / + grows one into the other. Like sliders it starts minimised unless the user
/// maximised it before (remembered by key), and the − / + by its label
/// flips it.
///
/// Like the slider: xValue/yValue are set by the user and moved(x, y)
/// reports only user changes, so bind them to your settings and write them
/// back in onMoved.
Item {
    id: root

    property string label: ""
    property real xValue: 0
    property real yValue: 0
    property real xFrom: -100
    property real xTo: 100
    property real yFrom: -100
    property real yTo: 100
    property real stepSize: 1
    property int decimals: PM.decimalsFor(stepSize)
    property string unit: ""
    //! Value units between grid lines; 0 picks a round step for about ten.
    property real gridStep: 0
    //! True: y grows downward, as on a screen. False: upward, as on a graph.
    property bool yDown: true
    //! The pad's width over its height; the canvas's by default.
    property real aspect: (xTo - xFrom) / (yTo - yFrom)
    property real defaultX: NaN
    property real defaultY: NaN
    //! The placed element's size, in value units, outlined round the dot (0: none).
    property real footprintWidth: 0
    property real footprintHeight: 0
    //! True: the dot is the element's top left corner (x / y are "left edge /
    //! top edge"), so the outline hangs right and down from it. False: the
    //! dot is its centre.
    property bool footprintFromCorner: false
    //! Other elements, faintly, for reference: [{ x, y, label }].
    property var ghosts: []
    //! What the panel remembers it by; the label if not given.
    property string key: label
    //! Minimised: a thumbnail of the grid, the boxes beside it.
    property bool compact: Theme.slidersStartMinimised && !PanelMemory.isMaximised(key)

    signal moved(real x, real y)

    readonly property color tint: Theme.accentIn(Window.window)
    readonly property bool pressed: ma.pressed

    implicitWidth: Theme.s(300)
    implicitHeight: head.height + (root.compact ? Math.max(pad.height, boxes.height)
                                                : pad.height + Theme.s(6) + boxes.height)
    //! The thumbnail's width: the canvas's shape, no taller than 48px.
    readonly property real thumbWidth: Math.min(Theme.s(72), Theme.s(48) * root.aspect)
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    //! Sets the position as the user would: snapped, kept on the pad, reported.
    function setXY(x, y) {
        x = PM.clamp(PM.snap(x, root.stepSize, root.xFrom), Math.min(root.xFrom, root.xTo), Math.max(root.xFrom, root.xTo))
        y = PM.clamp(PM.snap(y, root.stepSize, root.yFrom), Math.min(root.yFrom, root.yTo), Math.max(root.yFrom, root.yTo))
        if (x !== root.xValue || y !== root.yValue) { root.xValue = x; root.yValue = y; root.moved(x, y) }
    }
    function nudge(dx, dy, big) { const k = root.stepSize * (big ? 10 : 1); setXY(root.xValue + dx * k, root.yValue + dy * k) }
    function reset() { if (!isNaN(root.defaultX) && !isNaN(root.defaultY)) setXY(root.defaultX, root.defaultY) }
    function saveDefault() { root.defaultX = root.xValue; root.defaultY = root.yValue }
    readonly property bool isDefault: isNaN(root.defaultX) || isNaN(root.defaultY)
        || (Math.abs(root.xValue - root.defaultX) < root.stepSize / 2 && Math.abs(root.yValue - root.defaultY) < root.stepSize / 2)

    // value <-> pad pixels
    function px(v) { return (v - root.xFrom) / (root.xTo - root.xFrom) * pad.width }
    function py(v) { const f = (v - root.yFrom) / (root.yTo - root.yFrom); return (root.yDown ? f : 1 - f) * pad.height }
    function vx(p) { return root.xFrom + PM.clamp(p / pad.width, 0, 1) * (root.xTo - root.xFrom) }
    function vy(p) { const f = PM.clamp(p / pad.height, 0, 1); return root.yFrom + (root.yDown ? f : 1 - f) * (root.yTo - root.yFrom) }

    function niceStep(raw) {
        if (!(raw > 0)) return 1
        const p = Math.pow(10, Math.floor(Math.log10(raw))), n = raw / p
        return (n < 1.5 ? 1 : n < 3.5 ? 2 : n < 7.5 ? 5 : 10) * p
    }
    readonly property real grid: root.gridStep > 0 ? root.gridStep : niceStep(Math.abs(root.xTo - root.xFrom) / 10)
    function lines(from, to) {
        const lo = Math.min(from, to), hi = Math.max(from, to), out = []
        for (let v = Math.ceil(lo / root.grid) * root.grid; v <= hi + 1e-9 && out.length < 200; v += root.grid)
            out.push(Number(v.toFixed(6)))
        return out
    }

    // --- label row -----------------------------------------------------------
    Item {
        id: head
        width: parent.width
        height: root.label.length ? title.implicitHeight + Theme.rowGap : 0
        visible: height > 0
        Text {
            id: title
            width: parent.width - resetMark.width - sizeMark.width - Theme.s(16)
            text: root.label
            elide: Text.ElideRight
            color: Theme.text
            font.family: Theme.family
            font.pixelSize: Theme.titleSize
        }
        Text {
            id: resetMark
            anchors.right: sizeMark.left
            anchors.rightMargin: Theme.s(8)
            anchors.verticalCenter: title.verticalCenter
            text: "↺"   // ↺
            color: resetHover.hovered ? root.tint : Theme.textFaint
            font.family: Theme.family
            font.pixelSize: Theme.titleSize
            opacity: !root.isDefault && (hover.hovered || root.activeFocus) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.ease } }
            HoverHandler { id: resetHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { enabled: resetMark.opacity > 0; onTapped: root.reset() }
        }
        ParamSizeMark {
            id: sizeMark
            objectName: "sizeMark"
            anchors.right: parent.right
            anchors.verticalCenter: title.verticalCenter
            compact: root.compact
            shown: hover.hovered || root.activeFocus
            tint: root.tint
            onToggled: {
                root.compact = !root.compact
                PanelMemory.setMaximised(root.key, !root.compact)
            }
        }
    }

    // --- the pad -------------------------------------------------------------
    Rectangle {
        id: pad
        objectName: "pad"
        y: head.height
        width: root.compact ? root.thumbWidth : parent.width
        height: Math.round(width / Math.max(0.05, root.aspect))
        // minimising and maximising grow the one grid, not swap it
        Behavior on width { NumberAnimation { duration: Theme.ease; easing.type: Easing.OutCubic } }
        color: hover.hovered && !ma.pressed ? Theme.wellHover : Theme.well
        clip: true

        // the grid; the zero lines a little brighter
        Repeater {
            model: root.lines(root.xFrom, root.xTo)
            Rectangle {
                required property var modelData
                x: Math.round(root.px(modelData)); width: 1; height: pad.height
                color: modelData === 0 ? Theme.textFaint : Theme.line
                opacity: modelData === 0 ? 0.9 : root.compact ? 0 : 0.5
            }
        }
        Repeater {
            model: root.lines(root.yFrom, root.yTo)
            Rectangle {
                required property var modelData
                y: Math.round(root.py(modelData)); height: 1; width: pad.width
                color: modelData === 0 ? Theme.textFaint : Theme.line
                opacity: modelData === 0 ? 0.9 : root.compact ? 0 : 0.5
            }
        }

        // other elements, faintly
        Repeater {
            model: root.ghosts
            Item {
                required property var modelData
                x: Math.round(root.px(modelData.x)); y: Math.round(root.py(modelData.y))
                Rectangle {
                    readonly property int side: root.compact ? Theme.s(3) : Theme.s(7)
                    x: -Math.floor(side / 2); y: -Math.floor(side / 2); width: side; height: side
                    color: "transparent"; border.width: 1; border.color: Theme.textDim
                }
                Text {
                    visible: !root.compact
                    x: Theme.s(6); y: -Theme.s(6)
                    text: modelData.label || ""
                    color: Theme.textDim
                    font.family: Theme.family
                    font.pixelSize: Theme.smallSize
                }
            }
        }

        // the default, dotted, while the dot is away from it (and not on top of it)
        Item {
            objectName: "defaultMark"
            visible: !root.isDefault
                     && (Math.abs(root.px(root.defaultX) - root.px(root.xValue)) > side
                         || Math.abs(root.py(root.defaultY) - root.py(root.yValue)) > side)
            readonly property int side: root.compact ? Theme.s(7) : Theme.s(11)
            x: Math.round(root.px(root.defaultX)) - side / 2
            y: Math.round(root.py(root.defaultY)) - side / 2
            width: side; height: side
            Repeater {
                // a dotted square: dots round the edge, two pixels on, two off
                model: 4 * Math.floor(parent.side / Theme.s(4))
                Rectangle {
                    required property int index
                    readonly property int per: Math.floor(parent.side / Theme.s(4))
                    readonly property int edge: Math.floor(index / per)
                    readonly property real t: (index % per) * Theme.s(4)
                    x: edge === 0 ? t : edge === 1 ? parent.side - width : edge === 2 ? parent.side - width - t : 0
                    y: edge === 0 ? 0 : edge === 1 ? t : edge === 2 ? parent.side - height : parent.side - height - t
                    width: Theme.s(2); height: Theme.s(2)
                    color: Theme.text; opacity: 0.6
                }
            }
        }

        // crosshairs through the dot
        Rectangle { x: Math.round(root.px(root.xValue)); width: 1; height: pad.height; color: root.tint; opacity: 0.45 }
        Rectangle { y: Math.round(root.py(root.yValue)); height: 1; width: pad.width; color: root.tint; opacity: 0.45 }

        // the placed element's size
        Rectangle {
            visible: root.footprintWidth > 0 && root.footprintHeight > 0
            readonly property real w: Math.abs(root.px(root.xFrom + root.footprintWidth) - root.px(root.xFrom))
            readonly property real h: Math.abs(root.py(root.yFrom + root.footprintHeight) - root.py(root.yFrom))
            x: Math.round(root.px(root.xValue) - (root.footprintFromCorner ? 0 : w / 2))
            y: Math.round(root.py(root.yValue) - (root.footprintFromCorner ? 0 : h / 2))
            width: Math.round(w); height: Math.round(h)
            color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.12)
            border.width: 1; border.color: root.tint
        }

        // the dot: a hard square, ringed in the page colour so it reads on the grid
        Rectangle {
            id: dot
            objectName: "dot"
            readonly property int side: root.compact ? (ma.pressed ? Theme.s(7) : Theme.s(5))
                                                     : (ma.pressed ? Theme.s(11) : Theme.s(9))
            x: Math.round(root.px(root.xValue)) - Math.floor(side / 2)
            y: Math.round(root.py(root.yValue)) - Math.floor(side / 2)
            width: side; height: side
            color: root.tint
            border.width: 1; border.color: Theme.page
        }

        // keyboard focus
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1; border.color: root.tint
            opacity: root.activeFocus && !ma.focusedByMouse ? 0.6 : 0
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            enabled: root.enabled
            preventStealing: true
            cursorShape: Qt.CrossCursor
            property bool focusedByMouse: false
            property real startX: 0
            property real startY: 0
            property real startVX: 0
            property real startVY: 0
            property bool fine: false
            function rebase(m) { startX = m.x; startY = m.y; startVX = root.xValue; startVY = root.yValue }
            function snapped(v, base) { return Math.round((v - base) / root.grid) * root.grid + base }
            function place(m) {
                let x, y
                if (fine) {
                    // finely: a tenth of the pointer's travel, from where Shift went down
                    x = startVX + (root.vx(m.x) - root.vx(startX)) * 0.1
                    y = startVY + (root.vy(m.y) - root.vy(startY)) * 0.1
                } else {
                    x = root.vx(m.x); y = root.vy(m.y)
                }
                if (m.modifiers & Qt.ControlModifier) { x = snapped(x, 0); y = snapped(y, 0) }
                root.setXY(x, y)
            }
            onPressed: m => {
                focusedByMouse = true
                root.forceActiveFocus(Qt.MouseFocusReason)
                fine = !!(m.modifiers & Qt.ShiftModifier)
                rebase(m)
                if (!fine) place(m)
            }
            onPositionChanged: m => {
                if (!pressed) return
                const nowFine = !!(m.modifiers & Qt.ShiftModifier)
                if (nowFine !== fine) { fine = nowFine; rebase(m) }
                place(m)
            }
            onDoubleClicked: root.reset()
        }
    }

    HoverHandler { id: hover }

    onActiveFocusChanged: if (!activeFocus) ma.focusedByMouse = false
    Keys.onPressed: e => {
        const big = !!(e.modifiers & Qt.ShiftModifier)
        const up = root.yDown ? -1 : 1   // the Up key moves the dot up the screen
        ma.focusedByMouse = false
        switch (e.key) {
        case Qt.Key_Left: root.nudge(-1, 0, big); break
        case Qt.Key_Right: root.nudge(1, 0, big); break
        case Qt.Key_Up: root.nudge(0, up, big); break
        case Qt.Key_Down: root.nudge(0, -up, big); break
        case Qt.Key_Backspace: case Qt.Key_Delete: root.reset(); break
        default: return
        }
        e.accepted = true
    }

    // --- the values ----------------------------------------------------------
    Row {
        id: boxes
        // beside the thumbnail, or under the full grid
        x: root.compact ? pad.width + Theme.s(12) : 0
        y: root.compact ? pad.y + Math.round((pad.height - height) / 2) : pad.y + pad.height + Theme.s(6)
        spacing: Theme.s(14)
        Repeater {
            model: ["x", "y"]
            Row {
                id: axis
                required property string modelData
                spacing: Theme.s(6)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: axis.modelData
                    color: Theme.textDim
                    font.family: Theme.family
                    font.pixelSize: Theme.labelSize
                }
                ParamValueBox {
                    objectName: axis.modelData + "Box"
                    value: axis.modelData === "x" ? root.xValue : root.yValue
                    decimals: root.decimals
                    unit: root.unit
                    interactive: root.enabled
                    onSubmitted: v => axis.modelData === "x" ? root.setXY(v, root.yValue) : root.setXY(root.xValue, v)
                    onStepped: (direction, big) => axis.modelData === "x" ? root.nudge(direction, 0, big) : root.nudge(0, direction, big)
                    onFinished: { ma.focusedByMouse = true; root.forceActiveFocus(Qt.MouseFocusReason) }
                }
            }
        }
    }
}
