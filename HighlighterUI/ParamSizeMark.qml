import QtQuick

/// The min / max button by a control's label: a hairline minus to minimise,
/// a hairline plus to restore. Its owner shows it on hover (shown) and
/// flips its own compact in onToggled.
Item {
    id: mark

    property bool compact: false
    property bool shown: false
    property color tint: Theme.accent
    signal toggled()

    width: Theme.s(14); height: Theme.s(12)
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.ease } }
    readonly property color ink: sizeHover.hovered ? mark.tint : Theme.textFaint

    Rectangle {
        anchors.centerIn: parent
        width: Theme.s(10); height: Math.max(1, Theme.s(1))
        color: mark.ink
    }
    Rectangle {
        anchors.centerIn: parent
        visible: mark.compact
        width: Math.max(1, Theme.s(1)); height: Theme.s(10)
        color: mark.ink
    }
    HoverHandler { id: sizeHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { enabled: mark.opacity > 0; onTapped: mark.toggled() }
}
