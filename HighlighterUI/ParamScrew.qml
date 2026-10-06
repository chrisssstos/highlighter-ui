import QtQuick
import QtQuick.Shapes

/// A slotted screw head, for the corners of a plate. Hard-edged like the
/// rest of the kit; each one's slot sits at its own angle.
Shape {
    id: screw

    property real angle: 30
    property int size: Theme.s(10)

    width: size; height: size
    preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
    antialiasing: Theme.smooth
    readonly property real r: size / 2
    readonly property real slotX: Math.cos(angle * Math.PI / 180) * (r - 2)
    readonly property real slotY: Math.sin(angle * Math.PI / 180) * (r - 2)

    ShapePath {   // the countersink's shadow
        strokeColor: "transparent"; fillColor: Qt.rgba(0, 0, 0, 0.45)
        PathAngleArc { centerX: screw.r; centerY: screw.r; radiusX: screw.r; radiusY: screw.r; startAngle: 0; sweepAngle: 360 }
    }
    ShapePath {   // the head
        strokeColor: "transparent"; fillColor: Theme.screwFace
        PathAngleArc { centerX: screw.r; centerY: screw.r; radiusX: screw.r - 1; radiusY: screw.r - 1; startAngle: 0; sweepAngle: 360 }
    }
    ShapePath {   // light on its upper left
        strokeColor: Qt.rgba(1, 1, 1, 0.35); strokeWidth: 1; fillColor: "transparent"; capStyle: ShapePath.FlatCap
        PathAngleArc { centerX: screw.r; centerY: screw.r; radiusX: screw.r - 1.5; radiusY: screw.r - 1.5; startAngle: 160; sweepAngle: 110 }
    }
    ShapePath {   // the slot
        strokeColor: Qt.rgba(0, 0, 0, 0.7); strokeWidth: Math.max(1, Theme.s(1.5)); fillColor: "transparent"; capStyle: ShapePath.FlatCap
        startX: screw.r - screw.slotX; startY: screw.r - screw.slotY
        PathLine { x: screw.r + screw.slotX; y: screw.r + screw.slotY }
    }
}
