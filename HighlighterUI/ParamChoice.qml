import QtQuick

/// A row of options, one lit: presets, modes, shader 1/2/3. Wraps onto
/// more lines when it runs out of width. Left/Right move the choice.
Item {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentIn(Window.window)

    property string label: ""
    property var model: []
    property int currentIndex: 0
    property int cellHeight: Theme.s(26)
    property int cellMinWidth: Theme.s(30)
    signal activated(int index)

    readonly property string currentText: currentIndex >= 0 && currentIndex < model.length ? model[currentIndex] : ""

    implicitWidth: Theme.s(280)
    implicitHeight: (title.visible ? title.implicitHeight + Theme.rowGap : 0) + flow.implicitHeight
    activeFocusOnTab: true
    opacity: enabled ? 1 : 0.4

    function choose(i) {
        i = Math.max(0, Math.min(root.model.length - 1, i))
        if (i === root.currentIndex)
            return
        // Tells you first; it only lights the pick itself if you didn't, so
        // currentIndex bound to your own state stays bound.
        root.activated(i)
        if (root.currentIndex !== i) root.currentIndex = i
    }

    Text {
        id: title
        visible: root.label.length > 0
        width: parent.width
        text: root.label
        elide: Text.ElideRight
        color: Theme.text
        font.family: Theme.family
        font.pixelSize: Theme.labelSize
    }

    Flow {
        id: flow
        y: title.visible ? title.implicitHeight + Theme.rowGap : 0
        width: parent.width
        spacing: 1
        Repeater {
            model: root.model
            Rectangle {
                id: cell
                required property int index
                required property var modelData
                readonly property bool on: index === root.currentIndex
                width: Math.max(root.cellMinWidth, t.implicitWidth + Theme.s(18))
                height: root.cellHeight
                radius: Theme.radius
                color: on ? root.tint : (ca.containsMouse ? Theme.sunkenHover : Theme.sunken)
                Behavior on color { ColorAnimation { duration: Theme.quick } }
                border.width: on && root.activeFocus && !ca.focusedByMouse ? 1 : 0
                border.color: Theme.text
                Text {
                    id: t
                    anchors.centerIn: parent
                    text: cell.modelData
                    color: cell.on ? Theme.inkOf(root.tint) : Theme.textDim
                    font.family: Theme.family
                    font.pixelSize: root.cellHeight > Theme.s(34) ? Math.round(root.cellHeight * 0.55) : Theme.labelSize
                    font.weight: cell.on ? Font.DemiBold : Font.Normal
                }
                MouseArea {
                    id: ca
                    anchors.fill: parent
                    enabled: root.enabled
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    property bool focusedByMouse: true
                    onPressed: root.forceActiveFocus(Qt.MouseFocusReason)
                    onClicked: root.choose(cell.index)
                }
            }
        }
    }
    Keys.onLeftPressed: choose(currentIndex - 1)
    Keys.onRightPressed: choose(currentIndex + 1)
}
