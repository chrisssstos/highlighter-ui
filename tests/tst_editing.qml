import QtQuick
import QtTest
import HighlighterUI

// Run: qmltestrunner -import . -input tests/tst_editing.qml
Item {
    id: top
    width: 600; height: 400
    ParamSlider { id: s; x: 20; y: 20; width: 400; from: 0; to: 46; limitFrom: 0; value: 23; unit: "px"; label: "Text size" }
    // 1 unit per pixel along the bar (400 wide, less the 46px gutter)
    ParamSlider { id: d; x: 20; y: 120; width: 400; from: 0; to: 354; value: 100; key: "test.d" }
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
        //! True if two items' boxes overlap, in the slider's coordinates.
        function overlaps(a, b) {
            const p = a.mapToItem(d, 0, 0), q = b.mapToItem(d, 0, 0)
            return p.x < q.x + b.width && q.x < p.x + a.width && p.y < q.y + b.height && q.y < p.y + a.height
        }
        function test_defaultMarkNeverCrossesAnArrow() {
            const mark = findChild(d, "defaultMark"), up = findChild(d, "upArrow"), down = findChild(d, "downArrow")
            for (const compact of [true, false]) {
                d.compact = compact
                // walk the default across both arrows and the edge, a pixel at a time
                for (let def = 80; def <= 120; ++def) {
                    d.defaultValue = def
                    wait(0)
                    if (!mark.visible) continue
                    for (let i = 0; i < mark.children.length; ++i) {
                        const dot = mark.children[i]
                        if (!dot.visible || dot.width === undefined || dot.height === 0) continue
                        verify(!overlaps(dot, up), "a dot crosses the up arrow (default " + def + ", compact " + compact + ")")
                        verify(!overlaps(dot, down), "a dot crosses the down arrow (default " + def + ", compact " + compact + ")")
                    }
                }
            }
            d.defaultValue = NaN
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
            PanelMemory.store.maximised = "[]"
            s.compact = true
            const small = s.height
            const mark = findChild(s, "sizeMark")
            verify(mark, "the min / max button exists")
            // it only shows (and takes clicks) once the slider is hovered
            mouseMove(mark); wait(250)
            mouseClick(mark)
            verify(!s.compact, "a click maximises the slider")
            verify(s.height > small, "and it gets taller")
            verify(PanelMemory.isMaximised(s.key), "and the panel remembers it")

            // as if the app restarted: a new slider with the same key starts maximised
            const again = Qt.createQmlObject('import HighlighterUI; ParamSlider { key: "' + s.key + '" }', top)
            verify(!again.compact, "remembered across a restart")
            const other = Qt.createQmlObject('import HighlighterUI; ParamSlider { key: "never.touched" }', top)
            verify(other.compact, "others still start minimised")
            again.destroy(); other.destroy()

            mouseMove(mark); wait(250)
            mouseClick(mark)
            verify(s.compact)
            compare(s.height, small)
            verify(!PanelMemory.isMaximised(s.key), "minimising forgets it")
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
