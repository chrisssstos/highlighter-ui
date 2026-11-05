import QtQuick
import QtTest
import HighlighterUI

// Run: qmltestrunner -import . -input tests/tst_curve.qml
// A curve inside a page that scrolls, as in an app's panel: dragging its
// points must move them and never the page.
Item {
    id: top
    width: 500; height: 400
    ParamPage {
        id: page
        anchors.fill: parent
        Item { width: parent.width; height: 100 }
        ParamCurve {
            id: curve
            width: parent.width
            label: "roll up"
            duration: 7
            points: [{ t: 0, v: 0 }, { t: 0.5, v: 0.5 }, { t: 1, v: 1 }]
            defaultPoints: [{ t: 0, v: 0 }, { t: 0.5, v: 0.5 }, { t: 1, v: 1 }]
            onMoved: p => moves.push(p)
            property var moves: []
        }
        // enough below it that the page has somewhere to scroll
        Item { width: parent.width; height: 1200 }
    }

    TestCase {
        name: "CurveEditing"
        when: windowShown

        function plot() { return findChild(curve, "plot") }
        //! where a point { t, v } is on the plot
        function at(t, v) {
            const p = plot(), pad = Theme.s(6)
            return Qt.point(t * p.width, pad + (1 - v) * (p.height - 2 * pad))
        }
        function init() {
            page.contentY = 0
            curve.points = curve.defaultPoints.slice()
            curve.moves = []
        }

        function test_dragUpDoesNotScroll() {
            const p = plot(), a = at(0.5, 0.5)
            mousePress(p, a.x, a.y)
            // up and down in steps, as a hand does
            for (let dy = 0; dy <= 60; dy += 5) mouseMove(p, a.x, a.y - dy)
            for (let dy = 60; dy >= -40; dy -= 5) mouseMove(p, a.x, a.y - dy)
            mouseRelease(p, a.x, a.y + 40)
            compare(page.contentY, 0, "the page did not scroll")
            compare(curve.points.length, 3, "no point added")
            verify(curve.points[1].v < 0.5, "the middle point followed the drag down: " + curve.points[1].v)
            verify(curve.moves.length > 0, "moved() told the app")
        }

        function test_nearMissGrabsThePoint() {
            const p = plot(), a = at(0.5, 0.5)
            // a few pixels off the point's centre
            mousePress(p, a.x + Theme.s(9), a.y + Theme.s(6))
            mouseMove(p, a.x + Theme.s(9), a.y - 20)
            mouseRelease(p, a.x + Theme.s(9), a.y - 20)
            compare(curve.points.length, 3, "a near miss moves the point, it adds none")
            verify(curve.points[1].v > 0.5)
        }

        function test_clickEmptyAdds() {
            const p = plot(), a = at(0.25, 0.9)
            mouseClick(p, a.x, a.y)
            compare(curve.points.length, 4)
            fuzzyCompare(curve.points[1].t, 0.25, 0.02)
            fuzzyCompare(curve.points[1].v, 0.9, 0.02)
        }

        function test_rightClickRemoves() {
            const p = plot(), a = at(0.5, 0.5)
            mouseClick(p, a.x, a.y, Qt.RightButton)
            compare(curve.points.length, 2)
        }

        function test_doubleClickRemoves() {
            const p = plot(), a = at(0.5, 0.5)
            mouseDoubleClickSequence(p, a.x, a.y)
            compare(curve.points.length, 2)
        }

        function test_endsStay() {
            const p = plot(), a = at(1, 1)
            mouseClick(p, a.x - 1, a.y, Qt.RightButton)
            compare(curve.points.length, 3, "the last point can't be removed")
            mousePress(p, a.x - 1, a.y)
            mouseMove(p, a.x - 80, a.y + 30)
            mouseRelease(p, a.x - 80, a.y + 30)
            compare(curve.points[2].t, 1, "the last point stays at the end")
        }

        function test_readoutAndReset() {
            const p = plot(), a = at(0.5, 0.5)
            mouseMove(p, a.x, a.y)
            compare(curve.readoutText, "3.5 s · 50%", "hovering a point says where it is")
            verify(!curve.changed)
            mousePress(p, a.x, a.y); mouseMove(p, a.x, a.y - 30); mouseRelease(p, a.x, a.y - 30)
            verify(curve.changed, "Reset shows once it differs")
            const reset = findChild(curve, "reset")
            verify(reset.visible)
            mouseClick(reset)
            verify(!curve.changed, "Reset brings the defaults back")
            compare(curve.points[1].v, 0.5)
        }
    }
}
