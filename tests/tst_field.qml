import QtQuick
import QtTest
import HighlighterUI

// Run: qmltestrunner -import . -input tests/tst_field.qml
// ParamField with an app-wide Esc shortcut around it (an app that quits on Esc):
// Esc while editing must cancel the edit, not fire the shortcut.
Item {
    id: top
    width: 600; height: 300
    property int quits: 0
    property var accepted: []
    Shortcut { sequence: "Escape"; context: Qt.ApplicationShortcut; onActivated: top.quits++ }
    ParamField { id: f; x: 20; y: 20; width: 300; text: "WELCOME"; maximumLength: 10; onAccepted: (t) => top.accepted.push(t) }

    TestCase {
        name: "ParamField"
        when: windowShown
        function input() { return f.children[1].children[0] }
        function type(text) { for (const ch of text) keyClick(ch) }
        function init() { top.quits = 0; top.accepted = []; f.text = "WELCOME" }

        function test_escCancelsAndIsNotAShortcut() {
            mouseClick(input())
            verify(f.editing, "a click starts editing")
            keyClick(Qt.Key_End)
            type("XY")
            compare(input().text, "WELCOMEXY")
            keyClick(Qt.Key_Escape)
            compare(top.quits, 0, "the app-wide Esc did not fire")
            verify(!f.editing, "Esc ends the edit")
            compare(f.text, "WELCOME", "Esc puts the old text back")
            compare(top.accepted.length, 0, "nothing reported")
        }
        function test_escOutsideStillReachesTheApp() {
            top.forceActiveFocus()
            keyClick(Qt.Key_Escape)
            compare(top.quits, 1, "Esc anywhere else is still the app's")
        }
        function test_maximumLength() {
            mouseClick(input())
            keyClick(Qt.Key_End)
            type("12345")
            compare(input().text, "WELCOME123", "typing stops at maximumLength")
            keyClick(Qt.Key_Return)
            compare(top.accepted[0], "WELCOME123")
        }
    }
}
