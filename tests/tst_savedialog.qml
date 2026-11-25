import QtQuick
import QtTest
import HighlighterUI

// Run: qmltestrunner -import . -input tests/tst_savedialog.qml
// ParamSaveDialog with real clicks: a card that can't be used can't be
// picked, a usable one can, a chip opens its values, Save reports the card,
// Enter saves and Esc cancels.
Item {
    id: top
    width: 700; height: 700
    property var saved: []
    property var picks: []
    property var resets: []
    property var loads: []
    property int extras: 0
    property int reverts: 0

    ParamSaveDialog {
        id: dlg
        currentIndex: 2
        onAccepted: i => top.saved.push(i)
        onPicked: i => top.picks.push(i)
        onResetClicked: i => top.resets.push(i)
        onLoadClicked: i => top.loads.push(i)
        onExtraClicked: top.extras++
        onRevertClicked: top.reverts++
        revertText: "Restore to local"
        extraText: "Save to repo"
        loadText: "Load"
        resetText: "Delete save"
        targets: [
            { name: "Application", path: "C:/app/settings/a.toml", status: "existing", unusable: "Read-Only", detail: "read-only" },
            { name: "Application Platform", path: "%APP%/settings/%CFG_FOLDER%/a.toml", status: "new", unusable: "Not Set" },
            { name: "Local", path: "C:/local/a.toml", status: "existing", updates: ["a.b = 1"], overridden: ["c.d = 2 (Local Platform)"] },
            { name: "Local Platform", path: "C:/local/test/a.toml", status: "new", overrides: ["a.b = 1 (Application)"],
              saveText: "Save for this platform", resetText: "Delete platform save", resetEnabled: false, loadEnabled: false,
              removeText: "Also remove 1 value from Local Platform" }
        ]
    }

    TestCase {
        name: "ParamSaveDialog"
        when: windowShown

        function find(item, name, out) {
            if (item.objectName === name && out.indexOf(item) < 0) out.push(item)
            for (let i = 0; i < item.children.length; ++i) find(item.children[i], name, out)
            if (item.contentItem && item.contentItem !== item) find(item.contentItem, name, out)
            return out
        }
        function cards() { return find(dlg.contentItem, "saveCard", []).sort((a, b) => a.index - b.index) }
        function init() {
            top.saved = []; top.picks = []; top.resets = []; top.loads = []; top.extras = 0; top.reverts = 0
            dlg.currentIndex = 2; dlg.canSave = true
            dlg.open()
            tryVerify(() => dlg.opened)
            waitForRendering(dlg.contentItem)
        }
        function cleanup() { dlg.close(); tryVerify(() => !dlg.visible) }

        function test_cards() {
            compare(cards().length, 4)
        }
        function test_unusableCannotBePicked() {
            mouseClick(cards()[0])
            compare(dlg.currentIndex, 2, "a read-only card stays unpicked")
            compare(top.picks.length, 0, "and nothing is reported")
        }
        function test_pickAndSave() {
            mouseClick(cards()[3])
            compare(top.picks, [3])
            compare(dlg.currentIndex, 3)
            mouseClick(find(dlg.contentItem, "saveButton", [])[0])
            compare(top.saved, [3], "Save reports the picked card")
            tryVerify(() => !dlg.visible, 1000, "and closes")
        }
        function test_chipFiltersTheChanges() {
            const card = cards()[2]
            const chips = find(card, "saveChip", [])
            compare(chips.length, 2, "Updates and Overridden by; no Overrides")
            compare(dlg.changes.length, 2, "the Changes list: both lines")
            mouseClick(chips[1])
            compare(dlg.filter, "overridden")
            compare(dlg.changes.length, 1)
            compare(dlg.changes[0].kind, "overridden")
            mouseClick(chips[1])
            compare(dlg.filter, "", "a second click shows them all")
        }
        function test_changesFollowThePick() {
            mouseClick(cards()[3])
            compare(dlg.changes.length, 1)
            compare(dlg.changes[0].kind, "overrides")
        }
        function test_structuredChanges() {
            const before = dlg.targets
            const t = before.slice()
            t[2] = Object.assign({}, t[2], { changes: [
                { key: "a.b", from: "1", to: "2", kind: "updates", note: "" },
                { key: "c.d", from: "", to: "5", kind: "adds", note: "" }] })
            dlg.targets = t
            compare(dlg.changes.length, 2)
            compare(dlg.changes[1].key, "c.d")
            const view = find(dlg.contentItem, "changeList", [])[0]
            tryCompare(view, "count", 2, 1000, "one row per change")
            dlg.targets = before
        }
        function test_enterSavesEscCancels() {
            keyClick(Qt.Key_Return)
            compare(top.saved, [2])
            tryVerify(() => !dlg.visible)
            dlg.open(); tryVerify(() => dlg.opened)
            keyClick(Qt.Key_Escape)
            tryVerify(() => !dlg.visible)
            compare(top.saved, [2], "Esc saves nothing")
        }
            function test_nothingToSave() {
            dlg.canSave = false
            const save = find(dlg.contentItem, "saveButton", [])[0]
            verify(!save.enabled, "Save greys out")
            keyClick(Qt.Key_Return)
            compare(top.saved, [], "Enter saves nothing")
        }
        function test_reset() {
            mouseClick(find(dlg.contentItem, "resetButton", [])[0])
            compare(top.resets, [2], "for the picked card")
            compare(top.saved, [], "reset saves nothing")
            tryVerify(() => !dlg.visible, 1000, "and closes")
        }
            function test_buttonsFollowThePick() {
            const save = find(dlg.contentItem, "saveButton", [])[0]
            const reset = find(dlg.contentItem, "resetButton", [])[0]
            compare(save.text, "Save"); compare(reset.text, "Delete save"); verify(reset.enabled)
            mouseClick(cards()[3])
            compare(save.text, "Save for this platform")
            compare(reset.text, "Delete platform save")
            verify(!reset.enabled, "its own resetEnabled")
        }
            function test_load() {
            const load = find(dlg.contentItem, "loadButton", [])[0]
            verify(load.visible && load.enabled)
            mouseClick(cards()[3])
            verify(!load.enabled, "the card's own loadEnabled")
            mouseClick(cards()[2])
            mouseClick(load)
            compare(top.loads, [2], "Load reports the picked card")
            compare(top.saved, [], "and saves nothing")
            tryVerify(() => !dlg.visible, 1000, "and closes")
        }
            function test_extra() {
            const extra = find(dlg.contentItem, "extraButton", [])[0]
            verify(extra.visible && extra.enabled)
            compare(extra.text, "Save to repo")
            mouseClick(extra)
            compare(top.extras, 1, "reports the extra save")
            compare(top.saved, [], "not a card's save")
            tryVerify(() => !dlg.visible, 1000, "and closes")
        }
            function test_revert() {
            const revert = find(dlg.contentItem, "revertButton", [])[0]
            verify(revert.visible && revert.enabled)
            mouseClick(revert)
            compare(top.reverts, 1, "reports the revert")
            compare(top.resets, [], "not the reset")
            tryVerify(() => !dlg.visible, 1000, "and closes")
        }
            function test_removeOption() {
            const check = find(dlg.contentItem, "removeCheck", [])[0]
            verify(!check.visible, "no option on a card without one")
            mouseClick(cards()[3])
            verify(check.visible)
            compare(check.text, "Also remove 1 value from Local Platform")
            mouseClick(check)
            verify(dlg.removeChecked, "ticked")
            mouseClick(cards()[2])
            verify(!dlg.removeChecked, "a new pick clears it")
        }
    }
}
