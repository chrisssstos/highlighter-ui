import QtQuick
import QtQuick.Shapes

/// A seven-segment readout, as on a hardware display: `digits` places, each an
/// "8" printed faint with the segments of its character lit. Shows digits,
/// "-" and a "." after a digit; anything else is a blank place. The text is
/// right-aligned; places it does not use stay unlit 8s.
Item {
    id: root

    property string text: ""
    property int digits: 4
    property color ink: Theme.accent
    property color ghost: "#151a1d"
    //! The height of one digit; the width follows.
    property real digitHeight: Theme.s(24)

    readonly property real digitWidth: Math.round(root.digitHeight * 0.56)
    readonly property real thick: Math.max(2, Math.round(root.digitHeight * 0.12))
    readonly property real gap: Math.max(1, Math.round(root.thick * 0.25))
    readonly property real spacing: Math.round(root.digitHeight * 0.18)

    implicitWidth: root.digits * (root.digitWidth + root.spacing)
    implicitHeight: root.digitHeight

    // segments a b c d e f g, lit for each character
    readonly property var glyphs: ({
        "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
        "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcfgd", "-": "g"
    })

    //! The text as `digits` places: [segments, dot], right-aligned.
    readonly property var places: {
        const out = []
        const s = String(root.text)
        for (let i = 0; i < s.length; ++i) {
            const ch = s[i]
            if (ch === "." && out.length) { out[out.length - 1].dot = true; continue }
            out.push({ segs: root.glyphs[ch] ?? "", dot: false })
        }
        while (out.length < root.digits) out.unshift({ segs: "", dot: false })
        return out.slice(out.length - root.digits)
    }

    // Hexagonal segments, pointed at both ends, as an LCD prints them; the
    // digits lean a little, as most segment displays' do.
    readonly property string hSeg: "M0 50 L14 0 L86 0 L100 50 L86 100 L14 100 Z"
    readonly property string vSeg: "M50 0 L100 14 L100 86 L50 100 L0 86 L0 14 Z"
    property real lean: 0.09

    Row {
        spacing: root.spacing
        transform: Matrix4x4 {
            // lean right: x moves by lean * (height - y)
            matrix: Qt.matrix4x4(1, -root.lean, 0, root.lean * root.digitHeight,
                                 0, 1, 0, 0,
                                 0, 0, 1, 0,
                                 0, 0, 0, 1)
        }
        Repeater {
            model: root.places
            Item {
                id: digit
                required property var modelData
                width: root.digitWidth
                height: root.digitHeight
                readonly property real t: root.thick
                readonly property real g: root.gap
                function color(s) { return digit.modelData.segs.indexOf(s) >= 0 ? root.ink : root.ghost }

                // a: top, g: middle, d: bottom
                Hex { x: digit.t / 2 + digit.g; y: 0; width: digit.width - digit.t - 2 * digit.g; height: digit.t; horizontal: true; fill: digit.color("a") }
                Hex { x: digit.t / 2 + digit.g; y: (digit.height - digit.t) / 2; width: digit.width - digit.t - 2 * digit.g; height: digit.t; horizontal: true; fill: digit.color("g") }
                Hex { x: digit.t / 2 + digit.g; y: digit.height - digit.t; width: digit.width - digit.t - 2 * digit.g; height: digit.t; horizontal: true; fill: digit.color("d") }
                // f: top left, b: top right, e: bottom left, c: bottom right
                Hex { x: 0; y: digit.t / 2 + digit.g; width: digit.t; height: digit.height / 2 - digit.t / 2 - 2 * digit.g; fill: digit.color("f") }
                Hex { x: digit.width - digit.t; y: digit.t / 2 + digit.g; width: digit.t; height: digit.height / 2 - digit.t / 2 - 2 * digit.g; fill: digit.color("b") }
                Hex { x: 0; y: digit.height / 2 + digit.g; width: digit.t; height: digit.height / 2 - digit.t / 2 - 2 * digit.g; fill: digit.color("e") }
                Hex { x: digit.width - digit.t; y: digit.height / 2 + digit.g; width: digit.t; height: digit.height / 2 - digit.t / 2 - 2 * digit.g; fill: digit.color("c") }
                // the decimal point, in the gap after the digit
                Rectangle {
                    x: digit.width + (root.spacing - digit.t) / 2; y: digit.height - digit.t
                    width: digit.t; height: digit.t
                    color: digit.modelData.dot ? root.ink : root.ghost
                }
            }
        }
    }

    //! One pointed segment.
    component Hex: Shape {
        id: hex
        property bool horizontal: false
        property color fill
        preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
        antialiasing: Theme.smooth
        ShapePath {
            scale: Qt.size(hex.width / 100, hex.height / 100)
            strokeWidth: -1
            fillColor: hex.fill
            PathSvg { path: hex.horizontal ? root.hSeg : root.vSeg }
        }
    }
}
