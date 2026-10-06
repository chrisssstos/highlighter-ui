import QtQuick

/// A titled group of controls that folds open and shut, its body held in a
/// lime bracket. For "one open at a time", bind open to your own state and
/// set it in onToggled. Give its children width: parent.width.
Item {
    id: root

    property string title: ""
    property string note: ""
    property bool open: true
    property bool collapsible: true
    default property alias content: body.data
    property alias spacing: body.spacing

    signal toggled(bool open)

    implicitWidth: Theme.s(300)
    implicitHeight: header.height + frame.height

    Item {
        id: header
        width: parent.width
        height: Theme.s(30)

        ParamArrow {
            id: chevron
            visible: root.collapsible
            x: Theme.s(2)
            anchors.verticalCenter: parent.verticalCenter
            direction: Qt.RightArrow
            width: Theme.s(7); height: Theme.s(9)
            color: headArea.containsMouse ? Theme.accent : Theme.textDim
            rotation: root.open ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.ease; easing.type: Easing.OutCubic } }
        }
        Text {
            id: titleText
            x: root.collapsible ? Theme.s(16) : 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.title.toUpperCase()
            color: root.open ? Theme.text : (headArea.containsMouse ? Theme.text : Theme.textDim)
            font.family: Theme.family
            font.pixelSize: Theme.labelSize
            font.weight: Font.Bold
            font.letterSpacing: Theme.s(0.5)
        }
        Text {
            x: titleText.x + titleText.width + Theme.s(8)
            width: parent.width - x
            anchors.baseline: titleText.baseline
            text: root.note
            elide: Text.ElideRight
            color: Theme.textFaint
            font.family: Theme.family
            font.pixelSize: Theme.smallSize
        }
        MouseArea {
            id: headArea
            anchors.fill: parent
            enabled: root.collapsible
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: { root.open = !root.open; root.toggled(root.open) }
        }
    }

    Item {
        id: frame
        y: header.height
        width: parent.width
        height: root.open ? body.implicitHeight + 2 * pad : 0
        clip: true
        readonly property int pad: Theme.s(12)
        Behavior on height { NumberAnimation { duration: Theme.ease; easing.type: Easing.OutCubic } }

        Rectangle { anchors.fill: parent; color: Theme.raised }
        // the bracket: a bar with a foot at each end
        Rectangle { width: Theme.s(4); height: parent.height; color: Theme.accent }
        Rectangle { width: Theme.s(10); height: Theme.s(3); color: Theme.accent }
        Rectangle { y: parent.height - height; width: Theme.s(10); height: Theme.s(3); color: Theme.accent }

        Column {
            id: body
            x: Theme.s(18)
            y: frame.pad
            width: parent.width - x - Theme.s(14)
            spacing: Theme.controlGap
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.ease } }
        }
    }
}
