import QtQuick
import QtQuick.Shapes

/// A test card the size of the source: a grid every `step` pixels, the
/// centre marked, circles that show a stretch at a glance, and each slice's
/// input rectangle with its name, so its corners can be found on the output.
Item {
    id: root

    property var map: null
    property int step: 120

    Rectangle { anchors.fill: parent; color: "#151719" }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: "#3d4246"
            strokeWidth: 2
            fillColor: "transparent"
            PathMultiline {
                paths: {
                    const out = [], w = root.width, h = root.height, s = root.step
                    for (let x = 0; x <= w; x += s) out.push([Qt.point(x, 0), Qt.point(x, h)])
                    for (let y = 0; y <= h; y += s) out.push([Qt.point(0, y), Qt.point(w, y)])
                    return out
                }
            }
        }
        ShapePath {
            strokeColor: "#c9ced1"
            strokeWidth: 3
            fillColor: "transparent"
            PathMultiline {
                paths: {
                    const w = root.width, h = root.height
                    return [[Qt.point(w / 2, 0), Qt.point(w / 2, h)], [Qt.point(0, h / 2), Qt.point(w, h / 2)],
                            [Qt.point(0, 0), Qt.point(w, h)], [Qt.point(w, 0), Qt.point(0, h)]]
                }
            }
        }
    }

    // circles: round stays round when the mapping is right
    Repeater {
        model: [0.5, 0.15, 0.85]
        Rectangle {
            required property var modelData
            readonly property real d: Math.min(root.width, root.height) * 0.4
            x: root.width * modelData - d / 2
            y: root.height / 2 - d / 2
            width: d; height: d; radius: d / 2
            color: "transparent"
            border.color: "#c9ced1"; border.width: 3
        }
    }

    // each slice's input, numbered at its corners
    Repeater {
        model: root.map ? root.map.slices.length : 0
        Item {
            required property int index
            readonly property var s: { root.map.revision; return root.map.slices[index] }
            readonly property color tint: ["#def243", "#5cc8ff", "#f0b44a", "#e0664f", "#b48cff"][index % 5]
            x: s.input.x; y: s.input.y; width: s.input.width; height: s.input.height
            Rectangle { anchors.fill: parent; color: "transparent"; border.color: parent.tint; border.width: 8 }
            Text {
                anchors.centerIn: parent
                text: parent.s.name
                color: parent.tint
                font.pixelSize: Math.max(24, parent.height / 10); font.bold: true
            }
            Repeater {
                model: [[0, 0, "1"], [1, 0, "2"], [1, 1, "3"], [0, 1, "4"]]
                Text {
                    required property var modelData
                    x: modelData[0] * (parent.width - width - 40) + 20
                    y: modelData[1] * (parent.height - height - 20) + 10
                    text: modelData[2]
                    color: parent.tint
                    font.pixelSize: Math.max(20, parent.height / 14); font.bold: true
                }
            }
        }
    }
}
