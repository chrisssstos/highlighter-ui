import QtQuick

/// A titled group of controls that folds open and shut, its body held in a
/// lime bracket. For "one open at a time", bind open to your own state and
/// set it in onToggled. Give its children width: parent.width.
Item {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentIn(Window.window)

    property string title: ""
    property string note: ""
    property bool open: true
    property bool collapsible: true
    default property alias content: body.data
    property alias spacing: body.spacing

    signal toggled(bool open)

    //! Folds it open or shut, as a click on its title does. Tells you first;
    //! it only folds itself if you didn't, so open bound to your own state
    //! stays bound (one open at a time).
    function flip() {
        const want = !root.open
        root.toggled(want)
        if (root.open !== want) root.open = want
    }

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
            color: headArea.containsMouse ? root.tint : Theme.textDim
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
            style: Theme.titleStyle; styleColor: Theme.titleStyleColor
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
            onClicked: root.flip()
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

        ParamPlate {
            anchors.fill: parent
            screwInsetLeft: root.collapsible ? Theme.s(13) : Theme.s(5)
        }
        // the bracket, a bar with a foot at each end: only on a group that
        // folds, so it marks what can fold
        Item {
            anchors.fill: parent
            visible: root.collapsible
            Rectangle { width: Theme.s(4); height: parent.height; color: root.tint }
            Rectangle { width: Theme.s(10); height: Theme.s(3); color: root.tint }
            Rectangle { y: parent.height - height; width: Theme.s(10); height: Theme.s(3); color: root.tint }
        }

        Column {
            id: body
            // past the bracket; with none, the same margin both sides
            x: root.collapsible ? Theme.groupInset : Theme.sectionInset
            y: frame.pad
            width: parent.width - x - Theme.groupInsetEnd
            spacing: Theme.controlGap
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.ease } }
        }
    }
}
