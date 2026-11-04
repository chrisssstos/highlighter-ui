import QtQuick
import QtQuick.Controls.Basic as B

/// A scroll bar (8 px, 12 when hovered) that turns lime while it is held.
B.ScrollBar {
    id: bar

    //! The accent it draws in: the nearest one declared around it (see Theme).
    readonly property color tint: Theme.accentAt(bar, Window.window)
    policy: B.ScrollBar.AsNeeded
    padding: Theme.s(3)
    contentItem: Rectangle {
        implicitWidth: bar.hovered || bar.pressed ? Theme.s(12) : Theme.s(8)
        implicitHeight: implicitWidth
        radius: width / 2
        antialiasing: Theme.smooth
        color: bar.pressed ? bar.tint : bar.hovered ? Theme.arrow : Theme.line
        opacity: bar.size < 1 ? 1 : 0
        Behavior on implicitWidth { NumberAnimation { duration: Theme.quick } }
    }
    background: null
}
