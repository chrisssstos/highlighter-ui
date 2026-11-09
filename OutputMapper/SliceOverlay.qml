import QtQuick
import QtQuick.Shapes
import OutputMapper

/// A slice drawn as lines over its output (this item is the output): its
/// outline, the warp's grid, its control points and its name; the mask's
/// polygon in mask mode. For the editor's view and for "show on output", so
/// sizes are in this item's pixels (`unit` scales them for a big output).
Item {
    id: root

    property var slice: null
    property bool selected: false
    property int selectedPoint: -1
    property bool maskMode: false
    property color color: "#def243"
    property color otherColor: "#9aa3a0"
    property real unit: 1

    readonly property color ink: selected ? color : otherColor
    readonly property var pts: slice ? slice.points : []

    function px(p) { return Qt.point(p.x * width, p.y * height) }

    Shape {
        anchors.fill: parent
        visible: !!root.slice
        preferredRendererType: Shape.CurveRenderer
        // the warp's lines, faint
        ShapePath {
            strokeColor: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.35)
            strokeWidth: root.unit
            fillColor: "transparent"
            PathMultiline {
                paths: {
                    const s = root.slice
                    if (!s || root.width <= 0) return []
                    const n = Math.max(s.columns, s.rows, 5)
                    return Warp.lines(s.points, s.columns, s.rows, s.perspective, n, 24).map(l => l.map(p => root.px(p)))
                }
            }
        }
        // the outline
        ShapePath {
            strokeColor: root.ink
            strokeWidth: (root.selected ? 2 : 1.5) * root.unit
            fillColor: "transparent"
            PathPolyline {
                path: {
                    const s = root.slice
                    if (!s || root.width <= 0) return []
                    const o = Warp.outline(s.points, s.columns, s.rows, s.perspective, 24).map(p => root.px(p))
                    if (o.length) o.push(o[0])
                    return o
                }
            }
        }
        // the mask's polygon
        ShapePath {
            strokeColor: "#5cc8ff"
            strokeWidth: 1.5 * root.unit
            strokeStyle: ShapePath.DashLine
            fillColor: "transparent"
            PathPolyline {
                path: {
                    const m = root.slice?.mask ?? []
                    if (!root.selected || !m.length) return []
                    const o = m.map(p => root.px(p))
                    if (o.length >= 3) o.push(o[0])
                    return o
                }
            }
        }
    }

    // the control points (the mask's in mask mode)
    Repeater {
        model: root.selected ? (root.maskMode ? (root.slice?.mask ?? []) : root.pts) : []
        Rectangle {
            required property var modelData
            required property int index
            readonly property bool hot: !root.maskMode && index === root.selectedPoint
            readonly property real size: (hot ? 16 : 11) * root.unit
            x: modelData.x * root.width - size / 2
            y: modelData.y * root.height - size / 2
            width: size; height: size
            radius: root.maskMode ? 0 : size / 2
            color: hot ? root.color : "transparent"
            border.color: root.maskMode ? "#5cc8ff" : root.color
            border.width: 2 * root.unit
        }
    }

    // the name, at the slice's middle
    Text {
        visible: !!root.slice
        readonly property var mid: root.slice ? Warp.map(root.pts, root.slice.columns, root.slice.rows, root.slice.perspective, 0.5, 0.5) : ({ x: 0, y: 0 })
        x: mid.x * root.width - width / 2
        y: mid.y * root.height - height / 2
        text: root.slice?.name ?? ""
        color: root.ink
        font.pixelSize: 16 * root.unit
        font.bold: root.selected
        style: Text.Outline
        styleColor: "black"
    }
}
