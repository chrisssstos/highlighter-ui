import QtQuick
import QtTest
import HighlighterUI

// Run: qmltestrunner -import . -input tests/tst_editing.qml
Item {
    id: top
    width: 900; height: 600
    ParamSlider { id: s; x: 20; y: 20; width: 400; from: 0; to: 46; limitFrom: 0; value: 23; unit: "px"; label: "Text size" }
    // 1 unit per pixel along the bar (400 wide, less the 46px gutter)
    ParamSlider { id: d; x: 20; y: 120; width: 400; from: 0; to: 354; value: 100; key: "test.d" }
    // 200 x 200 px for -100..100 both ways: one unit per pixel, y down
    ParamXY { id: xy; x: 440; y: 20; width: 200; key: "test.xy"; label: "position"; xValue: 0; yValue: 0 }
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
                        verify(!up.visible || !overlaps(dot, up), "a dot crosses the up arrow (default " + def + ", compact " + compact + ")")
                        verify(!down.visible || !overlaps(dot, down), "a dot crosses the down arrow (default " + def + ", compact " + compact + ")")
                    }
                }
            }
            d.defaultValue = NaN
        }
        function test_minimisedHasNoArrows() {
            d.compact = true
            verify(!findChild(d, "upArrow").visible && !findChild(d, "downArrow").visible)
            d.compact = false
            verify(findChild(d, "upArrow").visible && findChild(d, "downArrow").visible)
        }
        function test_xyDragKeysTypeReset() {
            xy.compact = false
            xy.xValue = 0; xy.yValue = 0; xy.defaultX = 10; xy.defaultY = 20
            const pad = findChild(xy, "pad")
            compare(pad.width, 200); compare(pad.height, 200)
            mousePress(pad, 150, 50); mouseRelease(pad, 150, 50)
            compare(xy.xValue, 50, "click puts the dot there (x)")
            compare(xy.yValue, -50, "and y grows down the pad")
            mousePress(pad, 150, 50); mouseMove(pad, 60, 170); mouseRelease(pad, 60, 170)
            compare(xy.xValue, -40, "drag follows (x)"); compare(xy.yValue, 70, "drag follows (y)")
            keyClick(Qt.Key_Right); compare(xy.xValue, -39)
            keyClick(Qt.Key_Up); compare(xy.yValue, 69, "Up moves the dot up the screen")
            keyClick(Qt.Key_Left, Qt.ShiftModifier); compare(xy.xValue, -49)
            const box = findChild(xy, "yBox")
            mousePress(box, 5, 5); mouseRelease(box, 5, 5)
            type("-12"); keyClick(Qt.Key_Return)
            compare(xy.yValue, -12, "typed y")
            mouseDoubleClickSequence(pad, 20, 20)
            compare(xy.xValue, 10); compare(xy.yValue, 20, "double-click resets to the default")
            xy.yDown = false
            mousePress(pad, 100, 20); mouseRelease(pad, 100, 20)
            compare(xy.yValue, 80, "graph mode: y grows up the pad")
            xy.yDown = true
        }
        function test_xyMinMax() {
            PanelMemory.store.maximised = "[]"
            xy.compact = true
            const pair = findChild(xy, "pair"), pad = findChild(xy, "pad")
            verify(pair.visible && !pad.visible, "minimised: two sliders, no grid")
            const xs = findChild(xy, "xSlider"), ys = findChild(xy, "ySlider")
            xy.xValue = 25; xy.yValue = -30
            compare(xs.value, 25); compare(ys.value, -30)
            ys.setValue(40); ys.moved(40)
            compare(xy.yValue, 40, "the y slider moves the point")
            verify(!findChild(xs, "sizeMark").visible, "the bundled sliders have no min / max of their own")
            const mark = findChild(xy, "sizeMark")
            mouseMove(mark); wait(250); mouseClick(mark)
            verify(!xy.compact && pad.visible && !pair.visible, "maximised: the grid")
            verify(PanelMemory.isMaximised(xy.key), "remembered")
            const again = Qt.createQmlObject('import HighlighterUI; ParamXY { key: "' + xy.key + '" }', top)
            verify(!again.compact, "starts maximised after a restart"); again.destroy()
            mouseMove(mark); wait(250); mouseClick(mark)
            verify(xy.compact && !PanelMemory.isMaximised(xy.key))
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
