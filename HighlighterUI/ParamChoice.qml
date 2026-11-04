import QtQuick

/// A row of options, one lit: presets, modes, shader 1/2/3. Wraps onto
/// more lines when it runs out of width. Left/Right move the choice.
Item {
    id: root

    //! The accent it draws in: the nearest one declared around it (see Theme).
    readonly property color tint: Theme.accentAt(root, Window.window)

    property string label: ""
    property var model: []
    property int currentIndex: 0
    property int cellHeight: Theme.s(26)
    property int cellMinWidth: Theme.s(30)
    //! Indices of options drawn faint (e.g. empty preset slots): still
    //! clickable, so one can be picked and filled. A picked one is outlined
    //! in the accent, not filled, so an empty slot never reads as a full one.
    property var faint: []
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
                readonly property bool isFaint: (root.faint ?? []).indexOf(index) >= 0
                // picked and filled: the solid accent; picked but empty: only outlined
                readonly property bool lit: on && !isFaint
                width: Math.max(root.cellMinWidth, t.implicitWidth + Theme.s(18))
                height: root.cellHeight
                radius: Theme.radius
                color: lit ? Theme.litOf(root.tint) : (ca.containsMouse ? Theme.sunkenHover : Theme.sunken)
                Behavior on color { ColorAnimation { duration: Theme.quick } }
                // the light: the picked cell, its glow over its neighbours
                z: cell.on ? 1 : 0
                layer.enabled: Theme.glow && cell.lit && root.enabled
                layer.effect: ParamGlow { w: cell.width; h: cell.height; glowColor: root.tint }
                border.width: on && root.activeFocus && !ca.focusedByMouse ? 1 : 0
                border.color: Theme.text
                // classic: raised buttons, the chosen one pressed in
                Rectangle { anchors.fill: parent; visible: Theme.classic; color: "transparent"; border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.65) }
                ParamBevel { anchors.fill: parent; anchors.margins: 1; visible: Theme.classic; inset: cell.on; light: 0.2; dark: 0.4 }
                // an empty one picked: an accent outline, inside the cell
                Rectangle {
                    id: pickedOutline
                    anchors.fill: parent
                    visible: cell.on && cell.isFaint
                    layer.enabled: Theme.glow && visible && root.enabled
                    layer.effect: ParamGlow { w: pickedOutline.width; h: pickedOutline.height; thick: Theme.s(2); glowColor: root.tint }
                    color: "transparent"
                    border.width: Theme.s(2); border.color: root.tint
                }
                Text {
                    id: t
                    anchors.centerIn: parent
                    text: cell.modelData
                    color: cell.lit ? Theme.inkOf(root.tint) : cell.on ? root.tint : cell.isFaint ? Theme.textFaint : Theme.textDim
                    opacity: cell.isFaint && !cell.on ? 0.55 : 1
                    font.family: Theme.family
                    font.pixelSize: root.cellHeight > Theme.s(34) ? Math.round(root.cellHeight * 0.55) : Theme.labelSize
                    font.weight: cell.lit ? Font.DemiBold : Font.Normal
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
