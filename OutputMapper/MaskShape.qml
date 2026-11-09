import QtQuick
import QtQuick.Shapes

/// Black everywhere outside a polygon (points normalised to this item): a
/// slice's visible area. Fewer than three points: nothing.
Shape {
    id: root

    property var points: []
    property color color: "black"

    visible: points.length >= 3
    // plain geometry, built off the GUI thread: it changes on every move of a drag
    preferredRendererType: Shape.GeometryRenderer
    asynchronous: true

    ShapePath {
        fillColor: root.color
        strokeColor: "transparent"
        fillRule: ShapePath.OddEvenFill
        PathMultiline {
            paths: {
                const w = root.width, h = root.height
                // a margin round the item, so a point pulled outside it still cuts
                const m = Math.max(w, h)
                const outer = [Qt.point(-m, -m), Qt.point(w + m, -m), Qt.point(w + m, h + m), Qt.point(-m, h + m), Qt.point(-m, -m)]
                const inner = root.points.map(p => Qt.point(p.x * w, p.y * h))
                if (inner.length) inner.push(inner[0])
                return [outer, inner]
            }
        }
    }
}
