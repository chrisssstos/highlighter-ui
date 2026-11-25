import QtQuick
import QtQuick.Controls.Basic as B

/// Asks where a Save goes: one card per place the settings can be saved,
/// lowest priority first (as a layered settings viewer's: Application, Application
/// Platform, Local, Local Platform). Each card shows the file it would write,
/// whether that file exists, and chips for what saving there does to the
/// changed values: Updates (the file already sets them), Overrides (a file
/// above sets them; saved here, yours win) and Overridden by (a file below
/// sets them, so saving here has no effect). A chip opens its list.
/// A card that can't be used shows why, greyed out.
///
/// The kit knows nothing about files: the app fills `targets` and saves in
/// onAccepted. Like the other controls it tells you first: bind
/// currentIndex to your own state and set it in onPicked.
B.Popup {
    id: root

    //! The accent it draws in: the nearest one declared around it (see Theme).
    readonly property color tint: Theme.accentAt(root.parent, null)

    property string title: "Save to"
    //! The places, in order: { name, path, status ("existing" or "new"),
    //! unusable (a short reason, as "Read-Only" or "Not Set"; empty when it
    //! can be used), detail (the longer reason), updates, overrides,
    //! overridden (lists of lines, one per changed value; their counts are
    //! the chips) }, changes (what saving there writes, for the Changes list
    //! under the cards: { key, from, to, kind ("updates", "overrides",
    //! "overridden" or "adds"), note }; without it the list shows the
    //! updates / overrides / overridden lines), and optionally
    //! removeText (a "also remove these from the files above" option, shown
    //! as a check under the Changelog; removeEnabled), and
    //! what the buttons say for that card: saveText, saveTip, resetText, resetTip,
    //! resetEnabled, loadText, loadTip, loadEnabled (over the dialog's own
    //! below), so they follow the pick.
    property var targets: []
    property int currentIndex: -1
    //! Words beside the Save and reset icons: in a dialog the buttons have
    //! room, and words make its choices plain.
    property string saveText: "Save"
    //! The reset button (e.g. "Delete save"); it only shows with words,
    //! here or on the picked card. It sits apart, on the left, in danger.
    property string resetText: ""
    property string resetTip: ""
    //! Its icon: deleting a save by default.
    property string resetIcon: "delete"
    property bool resetEnabled: true
    //! The load button (e.g. "Load": that file's values onto the panel); it
    //! only shows with words, here or on the picked card.
    property string loadText: ""
    property string loadTip: ""
    property bool loadEnabled: true
    //! A save of its own kind beside Save, not a card (e.g. "Save to
    //! repo"); it only shows with words. The app saves in extraClicked.
    property string extraText: ""
    property string extraTip: ""
    property string extraIcon: "saveas"
    property bool extraEnabled: true
    //! A milder reset beside it (e.g. "Restore to local": drop the unsaved
    //! changes); it only shows with words.
    property string revertText: ""
    property string revertTip: ""
    property string revertIcon: "undo"
    property bool revertEnabled: true
    //! Whether there is anything to save (Save greys out without); a card's
    //! saveEnabled wins.
    property bool canSave: true
    //! The Changelog's legend: what its red (from) and green (to) values
    //! are, e.g. "in the file" / "on screen"; none by default.
    property string fromLabel: ""
    property string toLabel: ""
    //! What the Changelog says when the picked card has no changes.
    property string emptyText: ""

    // the picked card, and what the buttons say for it
    readonly property var current: root.usable(root.currentIndex) ? root.targets[root.currentIndex] : null
    readonly property string currentSaveText: root.current?.saveText ?? root.saveText
    readonly property string currentResetText: root.current?.resetText ?? root.resetText
    readonly property string currentResetTip: root.current?.resetTip ?? root.resetTip
    readonly property bool currentResetEnabled: root.current?.resetEnabled ?? root.resetEnabled
    readonly property bool currentSaveEnabled: root.current?.saveEnabled ?? root.canSave
    readonly property string currentLoadText: root.current?.loadText ?? root.loadText
    readonly property string currentLoadTip: root.current?.loadTip ?? root.loadTip
    readonly property bool currentLoadEnabled: root.current?.loadEnabled ?? root.loadEnabled

    //! The picked card's "also remove" option is ticked (cleared on each pick).
    property bool removeChecked: false
    readonly property string currentRemoveText: root.current?.removeText ?? ""
    readonly property bool currentRemoveEnabled: root.current?.removeEnabled ?? true
    //! The Changes list shows only this kind ("" all); a chip sets it.
    property string filter: ""
    //! The picked card's changes, filtered.
    readonly property var changes: {
        const t = root.current
        if (!t) return []
        let all = t.changes
        if (!all) {
            all = []
            for (const k of ["updates", "overrides", "overridden"])
                for (const line of (t[k] ?? []))
                    all.push({ key: line, from: "", to: "", kind: k, note: "" })
        }
        return root.filter === "" ? all : all.filter(c => c.kind === root.filter)
    }
    onCurrentIndexChanged: { root.filter = ""; root.removeChecked = false }

    //! A card was clicked; currentIndex follows unless you set it yourself.
    signal picked(int index)
    //! Save was pressed on a usable card.
    signal accepted(int index)
    //! Reset was pressed for the picked card; the dialog closes.
    signal resetClicked(int index)
    //! Load was pressed for the picked card; the dialog closes.
    signal loadClicked(int index)
    //! The extra save was pressed; the dialog closes.
    signal extraClicked()
    //! The revert was pressed; the dialog closes.
    signal revertClicked()

    function usable(i) { return i >= 0 && i < root.targets.length && !root.targets[i].unusable }
    function pick(i) {
        if (!root.usable(i)) return
        root.picked(i)
        if (root.currentIndex !== i) root.currentIndex = i
    }
    function accept() {
        if (!root.currentSaveEnabled || !root.usable(root.currentIndex)) return
        root.accepted(root.currentIndex)
        root.close()
    }

    parent: B.Overlay.overlay
    x: Math.round((parent ? parent.width - width : 0) / 2)
    y: Math.round((parent ? parent.height - height : 0) / 2)
    width: parent ? Math.min(Theme.s(880), parent.width - 2 * Theme.s(12)) : Theme.s(880)
    //! The Changes list beside the cards (on the right); under them when
    //! the window is too narrow.
    readonly property bool sideBySide: root.availableWidth >= Theme.s(700)
    height: parent ? Math.min(implicitHeight, parent.height - 2 * Theme.s(12)) : implicitHeight
    modal: true
    focus: true
    padding: Theme.s(14)
    closePolicy: B.Popup.CloseOnEscape | B.Popup.CloseOnPressOutside

    B.Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.5) }
    background: Rectangle {
        color: Theme.page
        radius: Theme.radius * 1.5
        border.width: 1; border.color: Theme.classic ? Qt.rgba(0, 0, 0, 0.7) : Theme.line
        ParamBevel { anchors.fill: parent; anchors.margins: 1; visible: Theme.classic; light: 0.2; dark: 0.4 }
    }

    contentItem: Item {
        focus: true   // Enter saves
        implicitHeight: heading.height + Theme.s(10)
                        + (root.sideBySide ? Math.max(cards.contentHeight, Theme.s(260))
                                           : cards.contentHeight + (changesPane.visible ? changesPane.height + Theme.s(12) : 0))
                        + Theme.s(12) + buttons.height
        Keys.onReturnPressed: root.accept()
        Keys.onEnterPressed: root.accept()

        Text {
            id: heading
            width: parent.width
            text: root.title
            color: Theme.text
            font.family: Theme.headingFamily
            font.pixelSize: Theme.titleSize
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            font.letterSpacing: Theme.s(1)
        }

        Flickable {
            id: cards
            y: heading.height + Theme.s(10)
            // side by side: the cards take a little over half
            width: root.sideBySide ? Math.round(parent.width * 0.54) : parent.width
            height: parent.height - y - Theme.s(12) - buttons.height
                    - (!root.sideBySide && changesPane.visible ? changesPane.height + Theme.s(12) : 0)
            contentHeight: list.implicitHeight
            clip: contentHeight > height
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: parent.width - (bar.visible ? Theme.s(10) : 0)
                spacing: Theme.s(6)

                Repeater {
                    model: root.targets
                    delegate: Item {
                        id: card
                        objectName: "saveCard"
                        required property var modelData
                        required property int index
                        readonly property bool usable: !modelData.unusable
                        readonly property bool chosen: index === root.currentIndex

                        width: list.width
                        height: body.implicitHeight + 2 * Theme.s(10)
                        opacity: usable ? 1 : 0.45

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius * 1.5
                            color: card.chosen ? Theme.raised
                                 : area.containsMouse && card.usable ? Theme.sunkenHover : Theme.sunken
                            // classic: the chosen card raised, the others sunk in
                            ParamBevel { anchors.fill: parent; visible: Theme.classic; inset: !card.chosen; light: card.chosen ? 0.2 : 0.1; dark: 0.45 }
                        }
                        // the chosen card: the group's bracket
                        Item {
                            visible: card.chosen
                            height: parent.height
                            Rectangle { width: Theme.s(4); height: parent.height; color: Theme.onPanel(root.tint) }
                            Rectangle { width: Theme.s(10); height: Theme.s(3); color: Theme.onPanel(root.tint) }
                            Rectangle { y: parent.height - height; width: Theme.s(10); height: Theme.s(3); color: Theme.onPanel(root.tint) }
                        }
                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: card.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.pick(card.index)
                            onDoubleClicked: { root.pick(card.index); root.accept() }
                        }

                        Column {
                            id: body
                            x: Theme.groupInset; y: Theme.s(10)
                            width: parent.width - x - Theme.groupInsetEnd
                            spacing: Theme.s(5)

                            Item {
                                width: parent.width
                                height: Math.max(name.implicitHeight, pill.height)
                                Text {
                                    id: name
                                    width: parent.width - pill.width - Theme.s(8)
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: card.modelData.name
                                    elide: Text.ElideRight
                                    color: card.chosen ? Theme.text : Theme.textDim
                                    font.family: Theme.family
                                    font.pixelSize: Theme.labelSize
                                    font.weight: card.chosen ? Font.Bold : Font.Normal
                                }
                                // Existing / New, or why it can't be used
                                Rectangle {
                                    id: pill
                                    // why it can't be used, else the card's badge ("Loaded"),
                                    // else Existing / New; the active card's in the accent
                                    readonly property string word: card.modelData.unusable
                                        ? card.modelData.unusable
                                        : card.modelData.badge ?? (card.modelData.status === "existing" ? "Existing" : "New")
                                    readonly property color ink: card.modelData.active && !card.modelData.unusable
                                        ? Theme.onPanel(root.tint) : Theme.textDim
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: pillText.implicitWidth + Theme.s(12)
                                    height: pillText.implicitHeight + Theme.s(4)
                                    radius: Theme.radius
                                    color: "transparent"
                                    border.width: 1
                                    border.color: card.modelData.active && !card.modelData.unusable ? pill.ink : Theme.line
                                    Text {
                                        id: pillText
                                        anchors.centerIn: parent
                                        text: pill.word
                                        color: pill.ink
                                        font.family: Theme.family
                                        font.pixelSize: Theme.smallSize
                                        font.weight: Font.Bold
                                        font.capitalization: Font.AllUppercase
                                        font.letterSpacing: Theme.s(1)
                                    }
                                }
                            }

                            ParamText {
                                width: parent.width
                                text: card.modelData.path
                                tone: "faint"; small: true; mono: true
                                wrapMode: Text.NoWrap
                                elide: Text.ElideMiddle
                            }
                            ParamText {
                                width: parent.width
                                visible: !card.usable && !!card.modelData.detail
                                text: card.modelData.detail ?? ""
                                small: true
                            }

                            // what saving here does to the changed values
                            Flow {
                                width: parent.width
                                spacing: Theme.s(4)
                                visible: card.usable && children.length > 1
                                Repeater {
                                    model: [
                                        { kind: "updates", word: "Updates", tone: "line" },
                                        { kind: "overrides", word: "Overrides", tone: "accent" },
                                        { kind: "overridden", word: "Overridden by", tone: "danger" }
                                    ].filter(c => (card.modelData[c.kind] ?? []).length > 0)
                                    delegate: Rectangle {
                                        id: chip
                                        objectName: "saveChip"
                                        required property var modelData
                                        readonly property color ink: modelData.tone === "accent" ? Theme.onPanel(root.tint)
                                                                   : modelData.tone === "danger" ? Theme.danger : Theme.textDim
                                        readonly property bool open: card.chosen && root.filter === modelData.kind
                                        width: chipText.implicitWidth + Theme.s(12)
                                        height: chipText.implicitHeight + Theme.s(4)
                                        radius: Theme.radius
                                        color: open ? Qt.rgba(ink.r, ink.g, ink.b, 0.18) : "transparent"
                                        border.width: 1; border.color: ink
                                        Text {
                                            id: chipText
                                            anchors.centerIn: parent
                                            text: chip.modelData.word + " " + card.modelData[chip.modelData.kind].length
                                            color: chip.ink
                                            font.family: Theme.family
                                            font.pixelSize: Theme.smallSize
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            // shows only these in the Changes list
                                            onClicked: {
                                                const on = !chip.open
                                                root.pick(card.index)
                                                root.filter = on ? chip.modelData.kind : ""
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            ParamScrollBar.vertical: ParamScrollBar { id: bar; visible: cards.interactive }
        }

        // what saving to the picked card writes, one value a row, scrolling
        Rectangle {
            id: changesPane
            objectName: "changesPane"
            visible: root.current !== null
            x: root.sideBySide ? cards.width + Theme.s(12) : 0
            y: root.sideBySide ? cards.y : cards.y + cards.height + Theme.s(12)
            width: root.sideBySide ? parent.width - x : parent.width
            height: root.sideBySide ? cards.height : Theme.s(170)
            radius: Theme.radius * 1.5
            color: Theme.sunken
            ParamBevel { anchors.fill: parent; visible: Theme.classic; inset: true; light: 0.1; dark: 0.45 }

            Text {
                id: changesTitle
                x: Theme.s(10); y: Theme.s(8)
                text: root.filter === "" ? "Changelog" : root.filter === "overridden" ? "Overridden by"
                      : root.filter.charAt(0).toUpperCase() + root.filter.slice(1)
                color: Theme.textDim
                font.family: Theme.family
                font.pixelSize: Theme.smallSize
                font.weight: Font.Bold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: Theme.s(1)
            }
            // the legend: red is the file's, green the panel's
            Row {
                anchors.right: parent.right; anchors.rightMargin: Theme.s(10)
                anchors.verticalCenter: changesTitle.verticalCenter
                spacing: Theme.s(8)
                visible: root.fromLabel !== "" || root.toLabel !== ""
                Repeater {
                    model: [{ text: root.fromLabel, colour: Theme.diffRemoved }, { text: root.toLabel, colour: Theme.diffAdded }]
                    delegate: Row {
                        required property var modelData
                        spacing: Theme.s(4)
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.s(10); height: Theme.s(10); radius: Theme.radius
                            color: Qt.rgba(modelData.colour.r, modelData.colour.g, modelData.colour.b, 0.35)
                            border.width: 1; border.color: modelData.colour
                        }
                        Text {
                            text: parent.modelData.text
                            color: Theme.textDim
                            font.family: Theme.family
                            font.pixelSize: Theme.smallSize
                        }
                    }
                }
            }
            ParamText {
                x: Theme.s(10); y: changesTitle.y + changesTitle.height + Theme.s(8)
                visible: root.changes.length === 0
                text: root.emptyText !== "" ? root.emptyText : root.canSave ? "Nothing here." : "No unsaved changes."
                tone: "faint"; small: true
            }
            ListView {
                id: changeList
                objectName: "changeList"
                x: Theme.s(10); y: changesTitle.y + changesTitle.height + Theme.s(6)
                width: parent.width - 2 * x
                height: parent.height - y - Theme.s(8) - (removeCheck.visible ? removeCheck.height + Theme.s(8) : 0)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                spacing: Theme.s(6)
                model: root.changes
                delegate: Column {
                    id: change
                    required property var modelData
                    // saving here does nothing to it (a file above sets it): dimmed
                    readonly property bool noEffect: modelData.kind === "overridden"
                    // clear of the scroll bar, which sits inside the list's right edge
                    width: changeList.width - (changeBar.visible ? Theme.s(14) : 0)
                    spacing: Theme.s(2)
                    opacity: noEffect ? 0.55 : 1
                    Item {
                        id: changeRow
                        objectName: "changeRow"
                        width: parent.width
                        readonly property real gap: Theme.s(10)
                        readonly property var values: [
                            { text: change.modelData.from, colour: Theme.diffRemoved },
                            { text: change.modelData.to, colour: Theme.diffAdded }
                        ].filter(v => v.text !== "")
                        // the values' own width, uncut, and the key's
                        readonly property real valuesWidth: values.reduce((w, v) => w + valueMeasure.advanceWidth(v.text) + Theme.s(10), 0)
                                                            + Math.max(0, values.length - 1) * diff.spacing
                        // too long to sit beside the key (a mapping's JSON): the
                        // values go on their own line under it, each cut to fit
                        readonly property bool stacked: changeKey.implicitWidth + gap + valuesWidth > width
                        height: stacked ? changeKey.implicitHeight + Theme.s(2) + diff.height
                                        : Math.max(changeKey.implicitHeight, diff.height)
                        FontMetrics { id: valueMeasure; font.family: Theme.mono; font.pixelSize: Theme.smallSize }
                        ParamText {
                            id: changeKey
                            width: changeRow.stacked ? parent.width : parent.width - diff.width - changeRow.gap
                            y: changeRow.stacked ? 0 : (parent.height - height) / 2
                            text: change.modelData.key
                            tone: "normal"; small: true; mono: true
                            wrapMode: Text.NoWrap
                            elide: Text.ElideLeft
                        }
                        // as a diff: the old value red, the new one green
                        Row {
                            id: diff
                            objectName: "changeValues"
                            x: changeRow.stacked ? 0 : parent.width - width
                            y: changeRow.stacked ? changeKey.implicitHeight + Theme.s(2) : (parent.height - height) / 2
                            spacing: Theme.s(4)
                            Repeater {
                                model: changeRow.values
                                delegate: Rectangle {
                                    required property var modelData
                                    // stacked: an even share of the line each
                                    readonly property real most: changeRow.stacked
                                        ? (changeRow.width - (changeRow.values.length - 1) * diff.spacing) / changeRow.values.length
                                        : Infinity
                                    width: Math.min(valueText.implicitWidth + Theme.s(10), most)
                                    height: valueText.implicitHeight + Theme.s(2)
                                    radius: Theme.radius
                                    color: Qt.rgba(modelData.colour.r, modelData.colour.g, modelData.colour.b, 0.2)
                                    Text {
                                        id: valueText
                                        anchors.centerIn: parent
                                        width: Math.min(implicitWidth, parent.width - Theme.s(10))
                                        text: parent.modelData.text
                                        color: parent.modelData.colour
                                        font.family: Theme.mono
                                        font.pixelSize: Theme.smallSize
                                        elide: Text.ElideMiddle
                                    }
                                }
                            }
                        }
                    }
                    ParamText {
                        visible: text !== ""
                        width: parent.width
                        text: change.modelData.note ?? ""
                        tone: "faint"; small: true
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight
                    }
                }
                ParamScrollBar.vertical: ParamScrollBar { id: changeBar; visible: changeList.contentHeight > changeList.height }
            }
            // the files above that would keep overriding what is saved here:
            // remove those values from them too
            ParamCheck {
                id: removeCheck
                objectName: "removeCheck"
                x: Theme.s(10)
                anchors.bottom: parent.bottom; anchors.bottomMargin: Theme.s(8)
                width: parent.width - 2 * x
                visible: root.currentRemoveText !== ""
                enabled: root.currentRemoveEnabled
                text: root.currentRemoveText
                checked: root.removeChecked
                onToggled: on => root.removeChecked = on
            }
        }

        // what else can be done: load the picked card's file, revert, reset
        Row {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            spacing: Theme.s(6)
            ParamButton {
                objectName: "loadButton"
                visible: root.currentLoadText !== ""
                icon: "load"
                text: root.currentLoadText
                enabled: root.currentLoadEnabled
                tip: root.currentLoadTip
                onClicked: { root.loadClicked(root.currentIndex); root.close() }
            }
            ParamButton {
                objectName: "revertButton"
                visible: root.revertText !== ""
                icon: root.revertIcon
                text: root.revertText
                enabled: root.revertEnabled
                tip: root.revertTip
                onClicked: { root.revertClicked(); root.close() }
            }
            ParamButton {
                objectName: "resetButton"
                visible: root.currentResetText !== ""
                icon: root.resetIcon
                text: root.currentResetText
                danger: true
                enabled: root.currentResetEnabled
                tip: root.currentResetTip
                onClicked: { root.resetClicked(root.currentIndex); root.close() }
            }
        }
        Row {
            id: buttons
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: Theme.s(6)
            ParamButton { text: "Cancel"; onClicked: root.close() }
            ParamButton {
                objectName: "extraButton"
                visible: root.extraText !== ""
                icon: root.extraIcon
                text: root.extraText
                enabled: root.extraEnabled
                tip: root.extraTip
                onClicked: { root.extraClicked(); root.close() }
            }
            ParamButton {
                objectName: "saveButton"
                icon: "save"
                text: root.currentSaveText
                accent: true
                enabled: root.currentSaveEnabled && root.usable(root.currentIndex)
                tip: root.current ? (root.current.saveTip ?? "Save to " + root.current.name) : ""
                onClicked: root.accept()
            }
        }
    }
}
