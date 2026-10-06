import QtQuick
import QtQuick.Controls.Basic as B

/// A scrolling column for a panel's controls, on the page colour. Give each
/// control width: parent.width (or less).
Flickable {
    id: root

    default property alias content: column.data
    property int padding: Theme.s(16)
    property alias spacing: column.spacing

    clip: true
    contentWidth: width
    contentHeight: column.implicitHeight + 2 * padding
    boundsBehavior: Flickable.StopAtBounds
    B.ScrollBar.vertical: ParamScrollBar {}

    Rectangle { parent: root; z: -1; anchors.fill: parent; color: Theme.page }

    Column {
        id: column
        x: root.padding
        y: root.padding
        width: root.width - 2 * root.padding - Theme.s(6)
        spacing: Theme.controlGap
    }
}
