import QtQuick
import "ParamMath.js" as PM

/// A setting shown as what it does: an LCD strip of small dot-matrix frames,
/// one picture per step from `from` to `to` (frames of them), like the
/// printed segments of a hardware display. Every segment is there, faint;
/// each frame's own picture is lit dimly, so the whole range reads at a
/// glance, and the frame nearest the value is lit bright, with a mark at the
/// exact value. Drag across the strip to set it, double-click to go back to
/// defaultValue, wheel or arrow keys to step; the value box under it takes a
/// typed value. A one-line hint under the label says what it does in words.
///
/// The picture comes from pattern(col, row, t): true lights the segment at
/// col, row of a cols x rows frame, for t from 0 (from) to 1 (to). Keep it
/// deterministic (hash() gives a steady noise), so the frames do not flicker.
///
/// Like ParamSlider: bind value, write it back in onMoved.
Item {
    id: root

    readonly property color tint: Theme.accentIn(Window.window)

    property string label: ""
    //! What it does, in a few plain words, under the label.
    property string hint: ""
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property int decimals: PM.decimalsFor(stepSize)
    property string unit: ""
    property real defaultValue: NaN
    property string key: label

    //! How many pictures across the range, and each one's segments.
    property int frames: 5
    property int cols: 20
    property int rows: 12
    //! function (col, row, t) -> bool
    property var pattern: function (c, r, t) { return false }

    signal moved(real value)

    //! The frame nearest the value, and where the value sits along the strip (0..1).
    readonly property real position: root.to > root.from ? PM.clamp((root.value - root.from) / (root.to - root.from), 0, 1) : 0
    readonly property int current: Math.round(root.position * (root.frames - 1))
    readonly property bool isDefault: isNaN(root.defaultValue) || Math.abs(root.value - root.defaultValue) < root.stepSize / 2

    implicitWidth: Theme.s(320)
    implicitHeight: head.height + Theme.rowGap + glass.height + box.height
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    function setValue(v) {
        v = PM.clamp(PM.snap(v, root.stepSize, root.from), root.from, root.to)
        if (v !== root.value) { root.value = v; root.moved(v) }
    }
    function step(direction, big) { setValue(root.value + direction * root.stepSize * (big ? 10 : 1)) }
    function reset() { if (!isNaN(root.defaultValue)) setValue(root.defaultValue) }
    function saveDefault() { root.defaultValue = root.value }

    //! A steady noise in 0..1 for a segment, for patterns that scatter.
    function hash(c, r, salt) {
        const x = Math.sin((c + 1) * 127.1 + (r + 1) * 311.7 + (salt || 0) * 74.7) * 43758.5453
        return x - Math.floor(x)
    }

    // --- the label and its hint ---------------------------------------------
    Column {
        id: head
        width: parent.width
        spacing: Theme.s(1)
        Row {
            width: parent.width
            spacing: Theme.s(8)
            Text {
                width: parent.width - resetMark.width - Theme.s(8)
                text: root.label
                elide: Text.ElideRight
                color: Theme.text
                font.family: Theme.family
                font.pixelSize: Theme.titleSize
                style: Theme.titleStyle
                styleColor: Theme.titleStyleColor
            }
            Text {
                id: resetMark
                text: "↺"
                visible: !root.isDefault
                color: ma2.containsMouse ? root.tint : Theme.textFaint
                font.family: Theme.family
                font.pixelSize: Theme.titleSize
                MouseArea { id: ma2; anchors.fill: parent; anchors.margins: -Theme.s(4); hoverEnabled: true; onClicked: root.reset() }
            }
        }
        Text {
            width: parent.width
            visible: root.hint !== ""
            text: root.hint
            wrapMode: Text.WordWrap
            color: Theme.textDim
            font.family: Theme.family
            font.pixelSize: Theme.smallSize
        }
    }

    // --- the glass ------------------------------------------------------------
    Rectangle {
        id: glass
        y: head.height + Theme.rowGap
        width: parent.width
        readonly property int pad: Theme.s(6)
        readonly property int gap: Theme.s(4)
        // a segment's size: as big as fits the width, whole pixels
        readonly property int seg: Math.max(1, Math.floor((width - 2 * pad - (root.frames - 1) * gap) / (root.frames * root.cols)))
        readonly property int frameW: seg * root.cols
        readonly property int frameH: seg * root.rows
        height: frameH + 2 * pad + Theme.s(5)
        color: "#0b0e10"
        border.width: Theme.classic ? 1 : 0
        border.color: Theme.line
        radius: Theme.radius

        Row {
            x: Math.round((glass.width - (root.frames * glass.frameW + (root.frames - 1) * glass.gap)) / 2)
            y: glass.pad
            spacing: glass.gap
            Repeater {
                model: root.frames
                Item {
                    id: frame
                    required property int index
                    readonly property real t: root.frames > 1 ? index / (root.frames - 1) : 0
                    readonly property bool lit: index === root.current
                    width: glass.frameW
                    height: glass.frameH
                    // every segment printed faint; this frame's picture dim, or bright when it is the value's
                    Repeater {
                        model: root.cols * root.rows
                        Rectangle {
                            required property int index
                            readonly property int c: index % root.cols
                            readonly property int r: Math.floor(index / root.cols)
                            readonly property bool on: root.pattern(c, r, frame.t)
                            x: c * glass.seg
                            y: r * glass.seg
                            width: Math.max(1, glass.seg - (glass.seg > 3 ? 1 : 0))
                            height: width
                            color: !on ? "#151a1d" : frame.lit ? root.tint : "#59656b"
                            antialiasing: false
                        }
                    }
                }
            }
        }
        // the exact value, under the strip
        Rectangle {
            x: glass.pad + root.position * (glass.width - 2 * glass.pad) - width / 2
            y: glass.height - Theme.s(4)
            width: Theme.s(10); height: Theme.s(2)
            color: root.tint
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            cursorShape: Qt.SizeHorCursor
            function at(mx) { return root.from + PM.clamp((mx - glass.pad) / (glass.width - 2 * glass.pad), 0, 1) * (root.to - root.from) }
            onPressed: m => { root.forceActiveFocus(); root.setValue(at(m.x)) }
            onPositionChanged: m => { if (pressed) root.setValue(at(m.x)) }
            onDoubleClicked: root.reset()
            onWheel: w => root.step(w.angleDelta.y > 0 ? 1 : -1, w.modifiers & Qt.ShiftModifier)
        }
    }

    ParamValueBox {
        id: box
        y: glass.y + glass.height
        x: PM.clamp(glass.pad + root.position * (glass.width - 2 * glass.pad) - width / 2, 0, root.width - width)
        value: root.value
        decimals: root.decimals
        unit: root.unit
        interactive: root.enabled
        onSubmitted: v => root.setValue(v)
        onStepped: (direction, big) => root.step(direction, big)
    }

    Keys.onPressed: e => {
        if (e.key === Qt.Key_Left || e.key === Qt.Key_Down) { root.step(-1, e.modifiers & Qt.ShiftModifier); e.accepted = true }
        else if (e.key === Qt.Key_Right || e.key === Qt.Key_Up) { root.step(1, e.modifiers & Qt.ShiftModifier); e.accepted = true }
    }
}
