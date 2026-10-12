import QtQuick
import "ParamMath.js" as PM

/// A setting's illustration: an LCD strip of small frames, one picture per
/// step of its range, as printed on a hardware display. Every segment is there,
/// faint; each frame's picture is lit dimly, so the whole range reads at a
/// glance; the frame nearest the value is lit bright, with a mark at the exact
/// value. Click a frame to jump to it (picked(t)).
///
/// A frame's picture is either a dot matrix, pattern(col, row, t) -> true for
/// a lit dot of a cols x rows frame, or a custom drawing: illustration, a
/// Component whose root is a ParamFrame holding ParamSegments.
///
/// ParamSlider draws one above its bar when given a pattern or an
/// illustration and maximised; it can also stand on its own.
Item {
    id: root

    readonly property color tint: Theme.accentIn(Window.window)

    property int frames: 5
    //! Where the value sits along the range, 0..1.
    property real position: 0
    property var pattern: null
    property Component illustration: null
    property int cols: 20
    property int rows: 12
    //! A custom frame's shape, width over height (a dot matrix's is cols / rows).
    property real aspect: 2.4

    signal picked(real t)

    readonly property int current: Math.round(PM.clamp(root.position, 0, 1) * (root.frames - 1))
    readonly property int pad: Theme.s(6)
    readonly property int gap: Theme.s(4)
    readonly property real frameW: (width - 2 * pad - (frames - 1) * gap) / frames
    // a dot's size: whole pixels, as big as fits
    readonly property int seg: Math.max(1, Math.floor(frameW / root.cols))
    readonly property real frameH: root.illustration ? Math.round(frameW / root.aspect) : seg * root.rows

    implicitWidth: Theme.s(320)
    implicitHeight: frameH + 2 * pad + Theme.s(5)

    Rectangle {
        anchors.fill: parent
        color: "#0b0e10"
        border.width: Theme.classic ? 1 : 0
        border.color: Theme.line
        radius: Theme.radius
    }

    Row {
        x: root.pad
        y: root.pad
        spacing: root.gap
        Repeater {
            model: root.frames
            Item {
                id: cell
                required property int index
                readonly property real t: root.frames > 1 ? index / (root.frames - 1) : 0
                readonly property bool lit: index === root.current
                width: Math.floor(root.frameW)
                height: root.frameH

                // the dot matrix
                Repeater {
                    model: root.illustration || !root.pattern ? 0 : root.cols * root.rows
                    Rectangle {
                        required property int index
                        readonly property int c: index % root.cols
                        readonly property int r: Math.floor(index / root.cols)
                        readonly property bool on: root.pattern(c, r, cell.t)
                        x: c * root.seg
                        y: r * root.seg
                        width: Math.max(1, root.seg - (root.seg > 3 ? 1 : 0))
                        height: width
                        color: !on ? "#151a1d" : cell.lit ? root.tint : "#59656b"
                        antialiasing: false
                    }
                }
                // or a custom drawing
                Loader {
                    id: custom
                    anchors.fill: parent
                    sourceComponent: root.illustration
                }
                Binding { target: custom.item; property: "t"; value: cell.t; when: custom.status === Loader.Ready }
                Binding { target: custom.item; property: "lit"; value: cell.lit; when: custom.status === Loader.Ready }
                Binding { target: custom.item; property: "ink"; value: root.tint; when: custom.status === Loader.Ready }
                Binding { target: custom.item; property: "width"; value: cell.width; when: custom.status === Loader.Ready }
                Binding { target: custom.item; property: "height"; value: cell.height; when: custom.status === Loader.Ready }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(cell.t)
                }
            }
        }
    }

    // the exact value
    Rectangle {
        x: root.pad + PM.clamp(root.position, 0, 1) * (root.width - 2 * root.pad) - width / 2
        y: root.height - Theme.s(4)
        width: Theme.s(10); height: Theme.s(2)
        color: root.tint
    }
}
