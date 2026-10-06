import QtQuick

/// A domed Phillips screw head in its countersink, for the corners of a
/// plate: a rendered sprite (tools/render_assets.py), each turned to its own
/// angle so they don't all line up.
Image {
    id: screw

    property real angle: 30
    property int size: Theme.s(11)

    width: size; height: size
    source: "textures/screw.png"
    sourceSize: Qt.size(64, 64)
    smooth: true
    mipmap: true
    rotation: angle
}
