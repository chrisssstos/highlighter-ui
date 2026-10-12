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
    property real aspect: 2.0
    //! The readout: the value as text ("" for none), its places and the unit printed beside it.
    property string readout: ""
    property int readoutDigits: 4
    property string unit: ""

    signal picked(real t)

    // A grey LCD with a hint of green, as on a meter: the glass, its rim, the segments printed
    // on it (barely darker than the glass), the pictures (pale) and the lit
    // frame and readout (the panel's accent).
    readonly property color glass: "#74776f"
    readonly property color rim: "#63665f"
    readonly property color rimLight: "#878a82"
    readonly property color ghost: "#6c6f68"
    readonly property color dim: "#b1b6ac"
    readonly property color lit: root.tint
    readonly property int current: Math.round(PM.clamp(root.position, 0, 1) * (root.frames - 1))

    // --- layout --------------------------------------------------------------
    readonly property int bezel: Theme.s(3)
    readonly property int pad: Theme.s(8)
    readonly property int tickH: Theme.s(5)
    // Laid out as a real display is: every segment has its own place. The
    // readout's slot comes first, sized from the display's width alone; the
    // frames get what is left, in a field of their own they cannot draw past.
    readonly property real digitH: Math.round(Math.max(Theme.s(18), Math.min(Theme.s(24), (width - 2 * (bezel + pad)) * 0.028)))
    readonly property real unitW: root.unit === "" ? 0 : unitMetrics.advanceWidth + Theme.s(5)
    readonly property real readoutW: root.readout === "" ? 0
        : root.readoutDigits * (Math.round(digitH * 0.56) + Math.round(digitH * 0.18)) + Math.round(digitH * 0.12) + unitW
    readonly property real readoutGap: root.readout === "" ? 0 : Theme.s(18)
    readonly property real fieldW: width - 2 * (bezel + pad) - readoutW - readoutGap
    // dot matrix: one dot field across the whole width, frames a dot apart
    // (a dot's pitch need not be whole pixels, so the field always fills it)
    readonly property real seg: Math.max(1, fieldW / (root.frames * root.cols + root.frames - 1))
    readonly property bool dots: !root.illustration && !!root.pattern
    readonly property real frameW: dots ? seg * root.cols : (fieldW - (root.frames - 1) * Theme.s(6)) / root.frames
    readonly property real frameGap: dots ? seg : Theme.s(6)
    readonly property real frameH: dots ? seg * root.rows : Math.round(frameW / root.aspect)

    implicitWidth: Theme.s(320)
    readonly property real contentH: Math.max(frameH + tickH + Theme.s(4), root.readout === "" ? 0 : digitH)
    implicitHeight: contentH + 2 * (bezel + pad)

    TextMetrics {
        id: unitMetrics
        text: root.unit.toUpperCase()
        font.family: Theme.family
        font.pixelSize: Theme.s(10)
        font.weight: Font.Bold
        font.letterSpacing: Theme.s(1)
    }

    // --- the glass -------------------------------------------------------------
    Rectangle {   // bezel
        anchors.fill: parent
        color: root.rim
        radius: Theme.s(2)
    }
    Rectangle {   // the pane
        id: pane
        anchors.fill: parent
        anchors.margins: root.bezel
        radius: Theme.s(2)
        color: root.glass
        border.width: 1
        border.color: root.rimLight
    }

    // --- the frames, in their own field ---------------------------------------------
    Item {
        id: field
        x: root.bezel
        y: root.bezel
        width: root.pad + root.fieldW + root.readoutGap / 2
        height: root.height - 2 * root.bezel
        clip: true
    Row {
        x: root.pad
        y: root.pad + (root.contentH - root.frameH - root.tickH - Theme.s(4)) / 2
        spacing: root.frameGap
        Repeater {
            model: root.frames
            Item {
                id: cell
                required property int index
                readonly property real t: root.frames > 1 ? index / (root.frames - 1) : 0
                readonly property bool lit: index === root.current
                width: root.frameW
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
                            width: Math.max(1, root.seg * 0.82)
                            height: width
                            color: !on ? root.ghost : cell.lit ? root.lit : root.dim
                            antialiasing: false
                        }
                    }
                    Loader { id: custom; anchors.fill: parent; sourceComponent: root.illustration }
                    Binding { target: custom.item; property: "t"; value: cell.t; when: custom.status === Loader.Ready }
                    Binding { target: custom.item; property: "lit"; value: cell.lit; when: custom.status === Loader.Ready }
                    Binding { target: custom.item; property: "ink"; value: root.lit; when: custom.status === Loader.Ready }
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
                        blur: 0.45
                        blurMax: 16
                        opacity: 0.35
                    }
                    Repeater {
                        model: root.dots && cell.lit ? root.cols * root.rows : 0
                        Rectangle {
                            required property int index
                            readonly property int c: index % root.cols
                            readonly property int r: Math.floor(index / root.cols)
                            x: c * root.seg
                            y: r * root.seg
                            width: Math.max(1, root.seg * 0.82)
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
                    color: cell.lit ? root.lit : root.ghost
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(cell.t)
                }
            }
        }
    }

    }

    // --- the readout, in its slot ------------------------------------------------------
    ParamSevenSeg {
        id: sevenSeg
        visible: root.readout !== ""
        x: root.width - root.bezel - root.pad - root.readoutW
        y: root.bezel + root.pad + (root.contentH - height) / 2
        digitHeight: root.digitH
        digits: root.readoutDigits
        text: root.readout
        ink: root.lit
        ghost: root.ghost
    }
    Text {
        id: unitText
        visible: root.readout !== "" && root.unit !== ""
        x: root.width - root.bezel - root.pad - root.unitW + Theme.s(5)
        y: sevenSeg.y + sevenSeg.height - height
        text: root.unit.toUpperCase()
        color: root.dim
        font.family: Theme.family
        font.pixelSize: Theme.s(10)
        font.weight: Font.Bold
        font.letterSpacing: Theme.s(1)
    }
}
