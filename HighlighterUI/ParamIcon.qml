import QtQuick
import QtQuick.Shapes

/// A drawn transport icon, hard-edged, every one on the same size so a row
/// of them lines up: "play", "pause", "stop", "record", "rewind" and
/// "forward" (the double triangles), "prev" and "next" (a triangle to a bar).
/// ParamButton draws one when its `icon` is one of these names.
Item {
    id: icon

    property string name: "play"
    property color color: Theme.arrow
    //! The icon's height; widths follow from it.
    property real size: Theme.s(12)

    readonly property real s: icon.size
    // each icon's natural width, so a button sizes round it
    width: name === "pause" ? Math.round(s * 0.8)
         : name === "stop" || name === "record" ? Math.round(s * 0.9)
         : name === "rewind" || name === "forward" ? Math.round(s * 1.3)
         : name === "prev" || name === "next" ? Math.round(s * 0.95)
         : Math.round(s * 0.85)   // play
    height: Math.round(s)

    // --- play: one triangle, full height ---------------------------------------
    Shape {
        visible: icon.name === "play"
        width: icon.width; height: icon.height
        preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
        antialiasing: Theme.smooth
        ShapePath {
            strokeWidth: -1; fillColor: icon.color
            startX: 0; startY: 0
            PathLine { x: icon.width; y: icon.height / 2 }
            PathLine { x: 0; y: icon.height }
            PathLine { x: 0; y: 0 }
        }
    }

    // --- pause: two bars, close together ----------------------------------------
    Rectangle { visible: icon.name === "pause"; width: Math.round(icon.width * 0.36); height: icon.height; color: icon.color }
    Rectangle { visible: icon.name === "pause"; x: icon.width - width; width: Math.round(icon.width * 0.36); height: icon.height; color: icon.color }

    // --- stop: a square; record: a dot ------------------------------------------
    Rectangle {
        visible: icon.name === "stop" || icon.name === "record"
        anchors.centerIn: parent
        width: icon.width; height: width
        radius: icon.name === "record" ? width / 2 : 0
        antialiasing: Theme.smooth
        color: icon.name === "record" ? Theme.danger : icon.color
    }

    // --- rewind / forward: two triangles nose to tail -----------------------------
    Repeater {
        model: icon.name === "rewind" || icon.name === "forward" ? 2 : 0
        Shape {
            id: tri
            required property int index
            readonly property bool back: icon.name === "rewind"
            x: index * icon.width / 2
            width: icon.width / 2; height: icon.height
            preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
            antialiasing: Theme.smooth
            ShapePath {
                strokeWidth: -1; fillColor: icon.color
                startX: tri.back ? tri.width : 0; startY: 0
                PathLine { x: tri.back ? 0 : tri.width; y: icon.height / 2 }
                PathLine { x: tri.back ? tri.width : 0; y: icon.height }
                PathLine { x: tri.back ? tri.width : 0; y: 0 }
            }
        }
    }

    // --- prev / next: a triangle against a bar ------------------------------------
    Item {
        id: step
        visible: icon.name === "prev" || icon.name === "next"
        anchors.fill: parent
        readonly property bool back: icon.name === "prev"
        readonly property real bar: Math.max(2, Math.round(icon.s * 0.2))
        Rectangle { x: step.back ? 0 : icon.width - width; width: step.bar; height: icon.height; color: icon.color }
        Shape {
            id: stepTri
            x: step.back ? step.bar : 0
            width: icon.width - step.bar; height: icon.height
            preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
            antialiasing: Theme.smooth
            ShapePath {
                strokeWidth: -1; fillColor: icon.color
                startX: step.back ? stepTri.width : 0; startY: 0
                PathLine { x: step.back ? 0 : stepTri.width; y: icon.height / 2 }
                PathLine { x: step.back ? stepTri.width : 0; y: icon.height }
                PathLine { x: step.back ? stepTri.width : 0; y: 0 }
            }
        }
    }
}
