import QtQuick
import QtQuick.Shapes

/// A small solid triangle, pointing left or right (or up / down).
Shape {
    id: arrow

    property int direction: Qt.RightArrow   // Qt.LeftArrow, RightArrow, UpArrow, DownArrow
    property color color: Theme.arrow

    // An explicit size: a Shape sets its own implicit size from its path,
    // which would feed back into the path and shrink it to nothing.
    width: Theme.arrowW
    height: Theme.arrowH
    preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
    antialiasing: Theme.smooth

    ShapePath {
        strokeWidth: -1
        fillColor: arrow.color
        startX: arrow.direction === Qt.LeftArrow ? arrow.width
              : arrow.direction === Qt.RightArrow ? 0
              : 0
        startY: arrow.direction === Qt.UpArrow ? arrow.height : 0
        PathLine {
            x: arrow.direction === Qt.LeftArrow ? arrow.width
             : arrow.direction === Qt.RightArrow ? 0
             : arrow.width
            y: arrow.direction === Qt.UpArrow ? arrow.height
             : arrow.direction === Qt.DownArrow ? 0
             : arrow.height
        }
        PathLine {
            x: arrow.direction === Qt.LeftArrow ? 0
             : arrow.direction === Qt.RightArrow ? arrow.width
             : arrow.width / 2
            y: arrow.direction === Qt.UpArrow ? 0
             : arrow.direction === Qt.DownArrow ? arrow.height
             : arrow.height / 2
        }
        PathLine { x: arrow.direction === Qt.LeftArrow ? arrow.width : 0
                   y: arrow.direction === Qt.UpArrow ? arrow.height : 0 }
    }

    Behavior on color { ColorAnimation { duration: Theme.quick } }
}
