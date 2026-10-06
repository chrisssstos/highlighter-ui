import QtQuick
import QtTest
import ParamKit

// Run: qmltestrunner -import . -input tests/tst_editing.qml
Item {
    id: top
    width: 600; height: 400
    ParamSlider { id: s; x: 20; y: 20; width: 400; from: 0; to: 46; limitFrom: 0; value: 23; unit: "px"; label: "Text size" }
    Rectangle { id: elsewhere; x: 20; y: 300; width: 100; height: 50 }

    TestCase {
        name: "ValueBoxEditing"
        when: windowShown
        function type(text) { for (const ch of text) keyClick(ch) }
        function init() { s.value = 23 }
        function box() { return findChild(s, "") && s.children.find(c => c.hasOwnProperty("submitted")) }

        function test_enterKeepsValue() {
            const b = box()
            mousePress(b, 5, 5); mouseRelease(b, 5, 5)
            verify(s.editing, "press opens the box")
            type("40+6")
            keyClick(Qt.Key_Return)
            verify(!s.editing, "Enter closes the box")
            compare(s.value, 46)
            verify(s.activeFocus, "the slider has the keyboard back")
        }
        function test_clickAwayKeepsValue() {
            const b = box()
            mousePress(b, 5, 5); mouseRelease(b, 5, 5)
            type("12")
            mouseClick(elsewhere)
            verify(!s.editing, "a click away closes the box")
            compare(s.value, 12)
        }
        function test_escDrops() {
            const b = box()
            mousePress(b, 5, 5); mouseRelease(b, 5, 5)
            type("30")
            keyClick(Qt.Key_Escape)
            verify(!s.editing)
            compare(s.value, 23)
        }
        function test_saveDefault() {
            s.defaultValue = 10
            verify(!s.isDefault, "away from the default: the dotted line shows")
            s.saveDefault()
            compare(s.defaultValue, 23)
            verify(s.isDefault, "saved: it goes")
            s.defaultValue = NaN
        }
        function test_minMaxButton() {
            const full = s.height
            const mark = findChild(s, "sizeMark")
            verify(mark, "the min / max button exists")
            mouseClick(mark)
            verify(s.compact, "a click minimises the slider")
            verify(s.height < full, "and it gets shorter")
            mouseClick(mark)
            verify(!s.compact)
            compare(s.height, full)
        }
        function test_junkThenClickAway() {
            const b = box()
            mousePress(b, 5, 5); mouseRelease(b, 5, 5)
            type("abc")
            keyClick(Qt.Key_Return)
            verify(s.editing, "unreadable text keeps it open on Enter")
            mouseClick(elsewhere)
            verify(!s.editing, "but a click away closes it")
            compare(s.value, 23)
        }
    }
}
