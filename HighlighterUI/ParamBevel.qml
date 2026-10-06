import QtQuick

/// One-pixel edges that make the thing under them look raised (light top
/// and left, dark bottom and right) or, with inset, sunk in.
Item {
    id: bevel

    property bool inset: false
    property real light: 0.10
    property real dark: 0.40

    readonly property color hi: Qt.rgba(1, 1, 1, light)
    readonly property color lo: Qt.rgba(0, 0, 0, dark)

    Rectangle { width: parent.width; height: 1; color: bevel.inset ? bevel.lo : bevel.hi }
    Rectangle { width: 1; height: parent.height; color: bevel.inset ? bevel.lo : bevel.hi }
    Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: bevel.inset ? bevel.hi : bevel.lo }
    Rectangle { x: parent.width - 1; width: 1; height: parent.height; color: bevel.inset ? bevel.hi : bevel.lo }
}
