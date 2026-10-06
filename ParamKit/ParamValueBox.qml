import QtQuick
import "ParamMath.js" as PM

/// The stroked box a value is shown in. Click it to type a value: Enter
/// keeps it, Esc drops it, clicking away keeps it, Up/Down step it. Typed
/// text may carry the unit or simple sums ("46px", "40+6"). It only reports
/// what was typed (submitted); its owner clamps it and sets value.
Item {
    id: box

    property real value: 0
    property int decimals: 0
    property string unit: ""
    property bool interactive: true
    property int align: Text.AlignLeft
    readonly property bool editing: input.activeFocus

    signal submitted(real v)
    signal stepped(int direction, bool big)

    implicitHeight: Theme.boxHeight
    implicitWidth: Math.max(Theme.s(30),
                            (editing ? input.contentWidth + Theme.s(14) : shown.implicitWidth)
                            + Theme.s(10))

    property bool bad: false
    property bool cancelling: false

    function begin() {
        if (!box.interactive) return
        box.bad = false
        input.text = PM.format(box.value, box.decimals)
        input.forceActiveFocus()
        input.selectAll()
    }
    function commit() {
        const v = PM.parse(input.text, box.unit)
        if (isNaN(v)) { box.bad = true; badTimer.restart(); return false }
        box.submitted(v)
        return true
    }
    function finish() { box.cancelling = true; input.focus = false; box.cancelling = false }

    Timer { id: badTimer; interval: 900; onTriggered: box.bad = false }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: box.editing ? Theme.editFill
             : hover.hovered && box.interactive ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
             : Qt.rgba(Theme.page.r, Theme.page.g, Theme.page.b, 0.85)
        border.width: 1
        border.color: box.bad ? Theme.danger : Theme.accent
        Behavior on color { ColorAnimation { duration: Theme.quick } }
    }

    Text {
        id: shown
        visible: !box.editing
        anchors.fill: parent
        leftPadding: Theme.s(5); rightPadding: Theme.s(5)
        horizontalAlignment: box.align
        verticalAlignment: Text.AlignVCenter
        text: PM.format(box.value, box.decimals) + box.unit
        color: Theme.accent
        font.family: Theme.family
        font.pixelSize: Theme.valueSize
    }

    TextInput {
        id: input
        visible: box.editing
        anchors.fill: parent
        leftPadding: Theme.s(5); rightPadding: Theme.s(5)
        horizontalAlignment: box.align
        verticalAlignment: Text.AlignVCenter
        color: Theme.editText
        selectionColor: Theme.editText
        selectedTextColor: Theme.editFill
        font: shown.font
        selectByMouse: true
        clip: true
        onAccepted: if (box.commit()) box.finish()
        onActiveFocusChanged: if (!activeFocus && !box.cancelling) box.commit()
        Keys.onEscapePressed: box.finish()
        Keys.onUpPressed: event => { if (box.commit()) { box.stepped(+1, event.modifiers & Qt.ShiftModifier); text = PM.format(box.value, box.decimals); selectAll() } }
        Keys.onDownPressed: event => { if (box.commit()) { box.stepped(-1, event.modifiers & Qt.ShiftModifier); text = PM.format(box.value, box.decimals); selectAll() } }
    }

    HoverHandler { id: hover; cursorShape: box.interactive ? Qt.IBeamCursor : Qt.ArrowCursor }
    TapHandler { enabled: box.interactive && !box.editing; onTapped: box.begin() }
}
