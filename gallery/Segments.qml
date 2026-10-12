import QtQuick
import QtQuick.Window
import HighlighterUI

/// A breakout page for trying ParamSegments before it goes anywhere else:
/// six of a client prototype's settings (a client project) drawn
/// as frames of what they do, beside the plain slider they would replace.
/// Run with run-segments.bat; "-- --shot=<png>" saves a picture and quits,
/// "-- --flat" for the flat skin.
Window {
    id: win
    width: 980
    height: 900
    visible: true
    color: Theme.page
    title: "HighlighterUI - segments"

    Component.onCompleted: {
        if (Qt.application.arguments.indexOf("--flat") >= 0) Theme.skin = "flat"
        const sca = Qt.application.arguments.find(a => a.startsWith("--scale="))
        if (sca) Theme.scale = Number(sca.substring(8))
    }
    Timer {
        interval: 1200
        running: Qt.application.arguments.some(a => a.startsWith("--shot="))
        onTriggered: {
            const file = Qt.application.arguments.find(a => a.startsWith("--shot=")).substring(7)
            win.contentItem.grabToImage(r => { r.saveToFile(file); Qt.quit() })
        }
    }

    // The values, as the probe's preset 3 has them.
    QtObject {
        id: v
        property real spread: 0.6
        property real fade: 707
        property real count: 5000
        property real speed: 220
        property real angle: 355
        property real size: 13
    }

    //! A steady noise in 0..1 for a segment, so the frames do not flicker.
    function n(c, r, salt) {
        const x = Math.sin((c + 1) * 127.1 + (r + 1) * 311.7 + salt * 74.7) * 43758.5453
        return x - Math.floor(x)
    }

    // A tiny stand-in for the message: two lines of "letters" (blocks with
    // gaps) on rows 3-4 and 7-8 of the 20 x 12 frame, up to column `upto`.
    function line(r) { return (r >= 3 && r <= 4) || (r >= 7 && r <= 8) }
    function letter(c, r, upto) {
        const line = win.line(r)
        return line && c < upto && (c % 4 !== 3) && win.n(c, r, 1) > 0.18
    }

    ParamPage {
        anchors.fill: parent

        ParamSection {
            width: parent.width
            title: "Dust: the crumble, as frames"
            note: "drag across a strip; double-click resets"

            ParamGrid {
                width: parent.width
                minColumnWidth: Theme.s(420)

                ParamSegments {
                    width: parent.width
                    label: "cloud spread"
                    hint: "how far the dust spreads above, below and behind the letters"
                    from: 0; to: 3; stepSize: 0.01; defaultValue: 0
                    value: v.spread; onMoved: x => v.spread = x
                    pattern: (c, r, t) => {
                        if (win.letter(c, r, 9)) return true
                        const reach = 3 + t * 6, mid = 5.5
                        const far = Math.abs(r - mid) / reach
                        const back = c >= 9 - Math.round(t * 6)
                        return back && c < 19 && far < 1 && win.n(c, r, 2) < 0.5 * (1 - far * 0.7)
                    }
                }
                ParamSegments {
                    width: parent.width
                    label: "fade behind the front"
                    hint: "how soft the edge is where the letters appear or go"
                    from: 0; to: 1200; stepSize: 1; unit: "px"; defaultValue: 260
                    value: v.fade; onMoved: x => v.fade = x
                    pattern: (c, r, t) => {
                        if (!win.line(r) || c % 4 === 3) return false
                        const edge = 14, w = 0.5 + t * 12
                        const k = (edge - c) / w
                        return k >= 1 || (k > 0 && win.n(c, r, 3) < k)
                    }
                }
                ParamSegments {
                    width: parent.width
                    label: "specks a sweep"
                    hint: "how much dust comes off the letters"
                    from: 0; to: 30000; stepSize: 50; defaultValue: 5000
                    value: v.count; onMoved: x => v.count = x
                    pattern: (c, r, t) => {
                        if (win.letter(c, r, 9)) return true
                        return c >= 9 && c < 19 && r >= 2 && r <= 9 && win.n(c, r, 4) < 0.04 + t * 0.6
                    }
                }
                ParamSegments {
                    width: parent.width
                    label: "speed"
                    hint: "how far the dust flies off before it fades"
                    from: 0; to: 800; stepSize: 1; unit: "px/s"; defaultValue: 220
                    value: v.speed; onMoved: x => v.speed = x
                    pattern: (c, r, t) => {
                        if (win.letter(c, r, 6)) return true
                        const reach = 6 + Math.round(1 + t * 13)
                        return c >= 6 && c < reach && r >= 2 && r <= 9 && win.n(c, r, 5) < 0.45 - (c - 6) * 0.02
                    }
                }
                ParamSegments {
                    width: parent.width
                    label: "direction"
                    hint: "which way the dust drifts (0 right, 90 down, 270 up)"
                    from: 0; to: 360; stepSize: 1; unit: "°"; defaultValue: 355
                    value: v.angle; onMoved: x => v.angle = x
                    frames: 5
                    pattern: (c, r, t) => {
                        // a source block in the middle, its dust streaming along the angle
                        const a = t * 2 * Math.PI, ox = 9.5, oy = 5.5
                        const dx = c - ox, dy = r - oy
                        if (Math.abs(dx) < 1 && Math.abs(dy) < 1) return true
                        const along = dx * Math.cos(a) + dy * Math.sin(a)
                        const across = Math.abs(-dx * Math.sin(a) + dy * Math.cos(a))
                        return along > 1 && along < 10 && across < 0.8 + along * 0.2 && win.n(c, r, 6) < 0.75 - along * 0.05
                    }
                }
                ParamSegments {
                    width: parent.width
                    label: "speck size"
                    hint: "how big each speck of dust is"
                    from: 1; to: 60; stepSize: 0.5; unit: "px"; defaultValue: 13
                    value: v.size; onMoved: x => v.size = x
                    pattern: (c, r, t) => {
                        // a few specks, growing from one segment to four
                        const s = 1 + Math.round(t * 3)
                        const cx = (c - 1) % 6, cy = (r - 1) % 5
                        const here = c >= 1 && r >= 1 && win.n(Math.floor((c - 1) / 6), Math.floor((r - 1) / 5), 7) < 0.85
                        return here && cx < s && cy < s
                    }
                }
            }
        }

        ParamSection {
            width: parent.width
            title: "The slider it replaces"
            ParamSlider {
                width: parent.width
                key: "segments.compare"
                label: "cloud spread (0 a tight band, 1+ a loose cloud like the mockup)"
                from: 0; to: 3; stepSize: 0.01; defaultValue: 0
                value: v.spread; onMoved: x => v.spread = x
            }
        }
    }
}
