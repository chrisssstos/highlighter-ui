import QtQuick
import "ParamMath.js" as PM

/// The stroked box a value is shown in. Press it to type a value: Enter
/// keeps it, Esc drops it, a click anywhere else keeps it, Up/Down step
/// it. Typed text may carry the unit or simple sums ("46px", "40+6"). It
/// only reports what was typed (submitted); its owner clamps it and sets
/// value. finished() fires when Enter, Esc or a click ends typing, so the
/// owner can take the keyboard back.
Item {
    id: box

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentIn(Window.window)

    property real value: 0
    property int decimals: 0
    property string unit: ""
    property bool interactive: true
    property int align: Text.AlignLeft
    property int boxHeight: Theme.boxHeight
    property int fontSize: Theme.valueSize
    readonly property bool editing: input.activeFocus

    signal submitted(real v)
    signal stepped(int direction, bool big)
    signal finished()

    implicitHeight: box.boxHeight
    // Just wide enough for the text and its padding (and the cursor, typing).
    implicitWidth: Math.max(Theme.s(20),
                            editing ? input.contentWidth + input.leftPadding + input.rightPadding + Theme.s(2)
                                    : shown.implicitWidth)

    property bool bad: false
    property bool ending: false

    function begin() {
        if (!box.interactive || box.editing) return
        box.bad = false
        input.text = PM.format(box.value, box.decimals)
        input.forceActiveFocus(Qt.MouseFocusReason)
        input.selectAll()
    }
    //! Reads the typed text and reports it; false (and a red flash) if it can't.
    function commit() {
        const v = PM.parse(input.text, box.unit)
        if (isNaN(v)) { box.bad = true; badTimer.restart(); return false }
        box.submitted(v)
        return true
    }
    //! Stops typing, keeping the typed value if keep and it reads. Text
    //! that can't be read keeps the box open (red) on Enter, but a click
    //! away always closes it, dropping that text.
    function end(keep, always) {
        if (!box.editing || box.ending) return
        if (keep && !box.commit() && !always) return
        box.ending = true
        input.focus = false
        box.ending = false
        box.finished()
    }

    Timer { id: badTimer; interval: 900; onTriggered: box.bad = false }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: box.editing ? Theme.editFill
             : hover.hovered && box.interactive ? Qt.rgba(box.tint.r, box.tint.g, box.tint.b, 0.16)
             : Theme.industrial ? Theme.screen   // a little LCD
             : Qt.rgba(Theme.page.r, Theme.page.g, Theme.page.b, 0.85)
        border.width: 1
        border.color: box.bad ? Theme.danger : box.tint
        ParamBevel { anchors.fill: parent; anchors.margins: 1; visible: Theme.industrial && !box.editing; inset: true; dark: 0.5; light: 0.08 }
    }

    Text {
        id: shown
        visible: !box.editing
        anchors.fill: parent
        leftPadding: Theme.s(4); rightPadding: Theme.s(4)
        horizontalAlignment: box.align
        verticalAlignment: Text.AlignVCenter
        text: PM.format(box.value, box.decimals) + box.unit
        color: box.tint
        font.family: Theme.family
        font.pixelSize: box.fontSize
    }

    TextInput {
        id: input
        visible: box.editing
        anchors.fill: parent
        leftPadding: Theme.s(4); rightPadding: Theme.s(4)
        horizontalAlignment: box.align
        verticalAlignment: Text.AlignVCenter
        color: Theme.editText
        selectionColor: Theme.editText
        selectedTextColor: Theme.editFill
        font: shown.font
        selectByMouse: true
        clip: true
        // Losing focus some other way (Tab, the window) keeps the value too.
        onActiveFocusChanged: if (!activeFocus && !box.ending) box.commit()
        // TextInput passes Enter on to its parents, so handle it here.
        Keys.onReturnPressed: e => { box.end(true); e.accepted = true }
        Keys.onEnterPressed: e => { box.end(true); e.accepted = true }
        Keys.onEscapePressed: e => { box.end(false); e.accepted = true }
        Keys.onUpPressed: e => box.stepWhileTyping(+1, e)
        Keys.onDownPressed: e => box.stepWhileTyping(-1, e)
    }
    function stepWhileTyping(direction, e) {
        e.accepted = true
        if (!box.commit()) return
        box.stepped(direction, e.modifiers & Qt.ShiftModifier)
        input.text = PM.format(box.value, box.decimals)
        input.selectAll()
    }

    HoverHandler { id: hover; cursorShape: box.interactive ? Qt.IBeamCursor : Qt.ArrowCursor }
    // Open on press, not release, so it answers at once.
    MouseArea {
        anchors.fill: parent
        enabled: box.interactive && !box.editing
        onPressed: box.begin()
    }

    // While typing, a press anywhere else in the window ends it, keeping
    // the value; the press still goes on to whatever was under it.
    MouseArea {
        parent: box.editing && box.Window.window ? box.Window.window.contentItem : box
        anchors.fill: parent
        z: 100000
        enabled: box.editing
        visible: box.editing
        acceptedButtons: Qt.AllButtons
        onPressed: m => {
            const p = mapToItem(box, m.x, m.y)
            if (p.x < 0 || p.y < 0 || p.x > box.width || p.y > box.height) box.end(true, true)
            m.accepted = false
        }
    }
}
