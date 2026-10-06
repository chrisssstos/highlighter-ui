import QtQuick
import QtQuick.Controls.Basic as B

/// A labelled drop-down list.
Item {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentIn(Window.window)

    property string label: ""
    property alias model: combo.model
    property alias currentIndex: combo.currentIndex
    readonly property alias currentText: combo.currentText
    signal activated(int index)

    implicitWidth: Theme.s(220)
    implicitHeight: (title.visible ? title.implicitHeight + Theme.rowGap : 0) + combo.height
    opacity: enabled ? 1 : 0.4

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

    B.ComboBox {
        id: combo
        y: title.visible ? title.implicitHeight + Theme.rowGap : 0
        width: parent.width
        height: Theme.s(26)
        font.family: Theme.family
        font.pixelSize: Theme.labelSize
        onActivated: i => root.activated(i)

        background: Rectangle {
            color: combo.hovered || combo.popup.visible ? Theme.sunkenHover : Theme.sunken
            border.width: 1
            border.color: combo.popup.visible || combo.visualFocus ? root.tint : "transparent"
            radius: Theme.radius
            Rectangle { width: Theme.s(3); height: parent.height; color: root.tint }
        }
        contentItem: Text {
            leftPadding: Theme.s(12)
            rightPadding: Theme.s(26)
            text: combo.displayText
            font: combo.font
            color: Theme.text
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        indicator: ParamArrow {
            x: combo.width - width - Theme.s(10)
            y: (combo.height - height) / 2
            direction: Qt.DownArrow
            width: Theme.arrowH; height: Theme.arrowW
            color: root.tint
            rotation: combo.popup.visible ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.ease } }
        }
        delegate: B.ItemDelegate {
            id: d
            required property int index
            required property var modelData
            width: combo.width
            height: Theme.s(26)
            highlighted: combo.highlightedIndex === index
            contentItem: Text {
                text: d.modelData
                leftPadding: Theme.s(4)
                font: combo.font
                color: d.highlighted ? Theme.inkOf(root.tint) : (combo.currentIndex === d.index ? root.tint : Theme.text)
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
            background: Rectangle { color: d.highlighted ? root.tint : "transparent" }
        }
        popup: B.Popup {
            y: combo.height + 1
            width: combo.width
            implicitHeight: Math.min(contentItem.implicitHeight + 2, Theme.s(26) * 8 + 2)
            padding: 1
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: combo.popup.visible ? combo.delegateModel : null
                currentIndex: combo.highlightedIndex
                boundsBehavior: Flickable.StopAtBounds
                B.ScrollBar.vertical: ParamScrollBar {}
            }
            background: Rectangle { color: Theme.sunken; border.width: 1; border.color: root.tint }
        }
    }
}
