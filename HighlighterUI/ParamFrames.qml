import QtQuick
import QtQuick.Effects
import "ParamMath.js" as PM

/// A setting's illustration, as one hardware display: a pane of dark glass with
/// a frame per step of the setting's range printed across it, and a
/// seven-segment readout of the value at its right. Every segment is printed,
/// faint; each frame's picture is lit dimly, so the whole range reads at a
/// glance; the frame nearest the value is lit bright and glows, and a tick under
/// it lights. Click a frame to jump to it (picked(t)).
///
/// A frame's picture is either a dot matrix, pattern(col, row, t) -> true for
/// a lit dot of a cols x rows frame (one dot field across the whole pane), or a
/// custom drawing: illustration, a Component whose root is a ParamFrame holding
/// ParamSegments.
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
    //! The readout: the value as text ("" for none), its places and the unit printed beside it.
    property string readout: ""
    property int readoutDigits: 4
    property string unit: ""

    signal picked(real t)

    readonly property color ghost: "#141a1d"
    readonly property color dim: "#56636a"
    readonly property int current: Math.round(PM.clamp(root.position, 0, 1) * (root.frames - 1))

    // --- layout --------------------------------------------------------------
    readonly property int bezel: Theme.s(3)
    readonly property int pad: Theme.s(8)
    readonly property int tickH: Theme.s(5)
    // the readout's room on the right
    readonly property real readoutW: root.readout === "" ? 0 : sevenSeg.width + Theme.s(22) + (unitText.visible ? unitText.width + Theme.s(4) : 0)
    readonly property real fieldW: width - 2 * (bezel + pad) - readoutW
    // dot matrix: one dot field, frames a dot apart
    readonly property int seg: Math.max(1, Math.floor(fieldW / (root.frames * root.cols + root.frames - 1)))
    readonly property bool dots: !root.illustration && !!root.pattern
    readonly property real frameW: dots ? seg * root.cols : (fieldW - (root.frames - 1) * Theme.s(6)) / root.frames
    readonly property real frameGap: dots ? seg : Theme.s(6)
    readonly property real frameH: dots ? seg * root.rows : Math.round(frameW / root.aspect)

    implicitWidth: Theme.s(320)
    implicitHeight: frameH + 2 * (bezel + pad) + tickH + Theme.s(4)

    // --- the glass -------------------------------------------------------------
    Rectangle {   // bezel
        anchors.fill: parent
        color: "#030405"
        radius: Theme.s(3)
    }
    Rectangle {   // the pane
        id: pane
        anchors.fill: parent
        anchors.margins: root.bezel
        radius: Theme.s(2)
        color: "#080b0d"
        border.width: 1
        border.color: "#171d21"
        // a soft light from above
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.045) }
                GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
    }

    // --- the frames --------------------------------------------------------------
    Row {
        x: root.bezel + root.pad
        y: root.bezel + root.pad
        spacing: root.frameGap
        Repeater {
            model: root.frames
            Item {
                id: cell
                required property int index
                readonly property real t: root.frames > 1 ? index / (root.frames - 1) : 0
                readonly property bool lit: index === root.current
                width: Math.floor(root.frameW)
                height: root.frameH
                // a picture stays in its own frame (the tick under it is drawn past it)
                Item { id: clipBox; anchors.fill: parent; clip: true }

                // the picture, every segment as printed
                Item {
                    parent: clipBox
                    anchors.fill: parent
                    Repeater {
                        model: root.dots ? root.cols * root.rows : 0
                        Rectangle {
                            required property int index
                            readonly property int c: index % root.cols
                            readonly property int r: Math.floor(index / root.cols)
                            readonly property bool on: root.pattern(c, r, cell.t)
                            x: c * root.seg
                            y: r * root.seg
                            width: Math.max(1, root.seg - (root.seg > 3 ? 1 : 0))
                            height: width
                            color: !on ? root.ghost : cell.lit ? root.tint : root.dim
                            antialiasing: false
                        }
                    }
                    Loader { id: custom; anchors.fill: parent; sourceComponent: root.illustration }
                    Binding { target: custom.item; property: "t"; value: cell.t; when: custom.status === Loader.Ready }
                    Binding { target: custom.item; property: "lit"; value: cell.lit; when: custom.status === Loader.Ready }
                    Binding { target: custom.item; property: "ink"; value: root.tint; when: custom.status === Loader.Ready }
                    Binding { target: custom.item; property: "width"; value: cell.width; when: custom.status === Loader.Ready }
                    Binding { target: custom.item; property: "height"; value: cell.height; when: custom.status === Loader.Ready }
                }
                // and the value's frame glowing, as lit LCD segments do: a
                // copy of its lit segments alone, blurred under the light
                Item {
                    parent: cell
                    anchors.fill: parent
                    visible: cell.lit
                    layer.enabled: cell.lit
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 0.6
                        blurMax: 24
                        brightness: 0.1
                        opacity: 0.7
                    }
                    Repeater {
                        model: root.dots && cell.lit ? root.cols * root.rows : 0
                        Rectangle {
                            required property int index
                            readonly property int c: index % root.cols
                            readonly property int r: Math.floor(index / root.cols)
                            x: c * root.seg
                            y: r * root.seg
                            width: Math.max(1, root.seg - (root.seg > 3 ? 1 : 0))
                            height: width
                            visible: root.pattern(c, r, cell.t)
                            color: root.tint
                        }
                    }
                    Loader { id: glowCustom; anchors.fill: parent; sourceComponent: cell.lit ? root.illustration : null }
                    Binding { target: glowCustom.item; property: "t"; value: cell.t; when: glowCustom.status === Loader.Ready }
                    Binding { target: glowCustom.item; property: "lit"; value: true; when: glowCustom.status === Loader.Ready }
                    Binding { target: glowCustom.item; property: "litOnly"; value: true; when: glowCustom.status === Loader.Ready }
                    Binding { target: glowCustom.item; property: "ink"; value: root.tint; when: glowCustom.status === Loader.Ready }
                    Binding { target: glowCustom.item; property: "width"; value: cell.width; when: glowCustom.status === Loader.Ready }
                    Binding { target: glowCustom.item; property: "height"; value: cell.height; when: glowCustom.status === Loader.Ready }
                }

                // its tick, printed under it
                Rectangle {
                    x: (cell.width - width) / 2
                    y: cell.height + Theme.s(4)
                    width: Theme.s(12); height: Math.max(2, Theme.s(2))
                    color: cell.lit ? root.tint : root.ghost
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(cell.t)
                }
            }
        }
    }

    // --- the readout -----------------------------------------------------------------
    ParamSevenSeg {
        id: sevenSeg
        visible: root.readout !== ""
        x: root.width - root.bezel - root.pad - width - (unitText.visible ? unitText.width + Theme.s(4) : 0)
        y: root.bezel + root.pad + (root.frameH - height) / 2
        digitHeight: Math.max(Theme.s(14), Math.min(Theme.s(34), root.frameH * 0.55))
        digits: root.readoutDigits
        text: root.readout
        ink: root.tint
        ghost: root.ghost
    }
    Text {
        id: unitText
        visible: root.readout !== "" && root.unit !== ""
        x: root.width - root.bezel - root.pad - width
        y: sevenSeg.y + sevenSeg.height - height
        text: root.unit.toUpperCase()
        color: root.dim
        font.family: Theme.family
        font.pixelSize: Theme.s(10)
        font.weight: Font.Bold
        font.letterSpacing: Theme.s(1)
    }
}
