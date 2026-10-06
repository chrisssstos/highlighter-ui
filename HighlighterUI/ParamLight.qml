import QtQuick

/// A small square that lights up while something is on (a sound playing, a
/// device connected): the accent when on, sunk into the page when off.
Rectangle {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentIn(Window.window)

    property bool on: false

    implicitWidth: Theme.s(10)
    implicitHeight: implicitWidth
    radius: Theme.radius
    color: root.on ? root.tint : Theme.sunken
    opacity: enabled ? 1 : 0.4
}
