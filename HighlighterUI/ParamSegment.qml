import QtQuick
import QtQuick.Shapes

/// A printed segment of a frame (ParamFrame), as on a hardware display: always
/// there, faint when off, lit when on. Plain, it is a hard-edged block; round,
/// a dot; with a path, any shape: an SVG path drawn in a 0..100 box that is
/// stretched to the segment's width and height (filled, or stroked when
/// stroke > 0). Rotate it like any item. Its colours come from the frame it
/// sits in (frame: its parent by default).
Item {
    id: seg

    property bool on: false
    property bool round: false
    //! An SVG path in a 0..100 box, e.g. "M0 50 L100 50" or "M0 0 L100 50 L0 100 Z".
    property string path: ""
    //! For a path: 0 fills it, more draws its outline this thick (px).
    property real stroke: 0
    property Item frame: parent

    // the copy a glow is drawn from shows only lit segments
    visible: seg.on || !(seg.frame?.litOnly ?? false)

    readonly property color color: !seg.on ? (seg.frame?.ghost ?? "#151a1d")
                                  : seg.frame?.lit ? (seg.frame?.ink ?? Theme.accent)
                                  : (seg.frame?.dim ?? "#59656b")

    Rectangle {
        anchors.fill: parent
        visible: seg.path === ""
        radius: seg.round ? Math.min(width, height) / 2 : 0
        antialiasing: seg.round && Theme.smooth
        color: seg.color
    }

    Shape {
        anchors.fill: parent
        visible: seg.path !== ""
        preferredRendererType: Theme.smooth ? Shape.CurveRenderer : Shape.GeometryRenderer
        antialiasing: Theme.smooth
        ShapePath {
            scale: Qt.size(seg.width / 100, seg.height / 100)
            fillColor: seg.stroke > 0 ? "transparent" : seg.color
            strokeColor: seg.stroke > 0 ? seg.color : "transparent"
            strokeWidth: seg.stroke > 0 ? seg.stroke : -1
            capStyle: ShapePath.FlatCap
            joinStyle: ShapePath.MiterJoin
            PathSvg { path: seg.path }
        }
    }
}
