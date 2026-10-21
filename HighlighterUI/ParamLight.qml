import QtQuick

/// A small square that lights up while something is on (a sound playing, a
/// device connected): the accent when on, sunk into the page when off.
Rectangle {
    id: root

    //! The accent it draws in: the nearest one declared around it (see Theme).
    readonly property color tint: Theme.accentAt(root, Window.window)

    property bool on: false

    implicitWidth: Theme.s(10)
    implicitHeight: implicitWidth
    radius: Theme.radius
    color: root.on ? Theme.litOf(root.tint) : Theme.sunken
    ParamGlow { anchors.fill: parent; z: -1; color: root.tint; strength: root.on && root.enabled ? 1 : 0 }
    opacity: enabled ? 1 : 0.4
}
