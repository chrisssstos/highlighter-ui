import QtQuick
import QtQuick.Controls.Basic as B

/// A thin scroll bar that turns lime while it is held.
B.ScrollBar {
    id: bar
    policy: B.ScrollBar.AsNeeded
    padding: Theme.s(2)
    contentItem: Rectangle {
        implicitWidth: bar.hovered || bar.pressed ? Theme.s(6) : Theme.s(4)
        implicitHeight: implicitWidth
        radius: width / 2
        antialiasing: Theme.smooth
        color: bar.pressed ? Theme.accent : bar.hovered ? Theme.arrow : Theme.line
        opacity: bar.size < 1 ? 1 : 0
        Behavior on implicitWidth { NumberAnimation { duration: Theme.quick } }
    }
    background: null
}
