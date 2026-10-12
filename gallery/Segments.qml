import QtQuick
import QtQuick.Window
import HighlighterUI

/// A breakout page for slider illustrations (ParamFrames above the bar, when
/// maximised), tried on a client prototype's settings (a client project) before they go anywhere else. Only settings a
/// picture explains get one; the rest stay plain sliders. Dot matrices
/// (pattern) and custom drawings of ParamSegments (illustration) side by side.
/// Run with run-segments.bat; "-- --shot=<png>" saves a picture and quits,
/// "-- --classic" for the old FL studio skin.
Window {
    id: win
    width: 1100
    height: 1000
    visible: true
    color: Theme.page
    title: "HighlighterUI - slider illustrations"

    Component.onCompleted: {
        // maximised, so the illustrations show (a minimised slider is a thin bar)
        Theme.slidersStartMinimised = false
        if (Qt.application.arguments.indexOf("--classic") >= 0) Theme.skin = "classic"
        const sca = Qt.application.arguments.find(a => a.startsWith("--scale="))
        if (sca) Theme.scale = Number(sca.substring(8))
    }
    Timer {
        interval: 1500
        running: Qt.application.arguments.some(a => a.startsWith("--shot="))
        onTriggered: {
            const file = Qt.application.arguments.find(a => a.startsWith("--shot=")).substring(7)
            const sc = Qt.application.arguments.find(a => a.startsWith("--scroll="))
            if (sc) page.contentY = Number(sc.substring(9))
            win.contentItem.grabToImage(r => { r.saveToFile(file); Qt.quit() })
        }
    }

    // The values, as the probe's preset 3 has them.
    QtObject {
        id: v
        property real fade: 707; property real ragged: 70; property real grain: 0
        property real spread: 0.6; property real count: 5000; property real jitter: 18
        property real speed: 220; property real angle: 355; property real turbulence: 80
        property real friction: 0.6; property real life: 3200
        property real size: 13
        property real revealMs: 2800; property real hideMs: 2200; property real gapMs: 1200
    }

    //! A steady noise in 0..1 for a dot, so the frames do not flicker.
    function n(c, r, salt) {
        const x = Math.sin((c + 1) * 127.1 + (r + 1) * 311.7 + salt * 74.7) * 43758.5453
        return x - Math.floor(x)
    }
    // Two lines of "letters" (blocks with gaps) on rows 3-4 and 7-8, up to column upto.
    function line(r) { return (r >= 3 && r <= 4) || (r >= 7 && r <= 8) }
    function letter(c, r, upto) { return win.line(r) && c < upto && c % 4 !== 3 && win.n(c, r, 1) > 0.18 }

    ParamPage {
        id: page
        anchors.fill: parent

        ParamText {
            width: parent.width
            text: "Sliders keep their bar; a picture above it shows what the setting does across its range, the value's frame lit. Only where a picture helps. Minimise a slider (the square by its label) and the picture goes."
        }

        ParamSection {
            width: parent.width
            title: "Front"
            ParamSlider {
                width: parent.width
                key: "seg.fade"; label: "fade behind the front"
                from: 0; to: 1200; unit: "px"; defaultValue: 260
                value: v.fade; onMoved: x => v.fade = x
                pattern: (c, r, t) => {
                    if (!win.line(r) || c % 4 === 3) return false
                    const k = (14 - c) / (0.5 + t * 12)
                    return k >= 1 || (k > 0 && win.n(c, r, 3) < k)
                }
            }
            ParamSlider {
                width: parent.width
                key: "seg.ragged"; label: "ragged edge"
                from: 0; to: 400; unit: "px"; defaultValue: 70
                value: v.ragged; onMoved: x => v.ragged = x
                // the letters' edge as a zigzag, deeper as it grows
                illustration: Component {
                    ParamFrame {
                        id: f
                        ParamSegment {
                            anchors.fill: parent
                            on: true
                            path: {
                                const a = 3 + f.t * 26, pts = ["M0 8"]
                                for (let i = 0; i <= 8; ++i) pts.push("L" + (50 + (i % 2 ? a : -a)).toFixed(1) + " " + (8 + i * 10.5).toFixed(1))
                                return pts.join(" ") + " L0 92 Z"
                            }
                        }
                    }
                }
            }
            ParamSlider {
                width: parent.width
                key: "seg.grain"; label: "fade breaks into specks"
                from: 0; to: 1; stepSize: 0.01; defaultValue: 0.35
                value: v.grain; onMoved: x => v.grain = x
            }
        }

        ParamSection {
            width: parent.width
            title: "Crumbling: where the dust comes from"
            ParamSlider {
                width: parent.width
                key: "seg.spread"; label: "cloud spread"
                from: 0; to: 3; stepSize: 0.01; defaultValue: 0
                value: v.spread; onMoved: x => v.spread = x
                pattern: (c, r, t) => {
                    if (win.letter(c, r, 9)) return true
                    const far = Math.abs(r - 5.5) / (3 + t * 6)
                    return c >= 9 - Math.round(t * 6) && c < 19 && far < 1 && win.n(c, r, 2) < 0.5 * (1 - far * 0.7)
                }
            }
            ParamSlider {
                width: parent.width
                key: "seg.count"; label: "specks a sweep"
                from: 0; to: 30000; stepSize: 50; defaultValue: 5000
                value: v.count; onMoved: x => v.count = x
                pattern: (c, r, t) => win.letter(c, r, 9) || (c >= 9 && c < 19 && r >= 2 && r <= 9 && win.n(c, r, 4) < 0.04 + t * 0.6)
            }
            ParamSlider {
                width: parent.width
                key: "seg.jitter"; label: "scatter round a letter"
                from: 0; to: 200; unit: "px"; defaultValue: 18
                value: v.jitter; onMoved: x => v.jitter = x
            }
        }

        ParamSection {
            width: parent.width
            title: "Crumbling: how it moves"
            ParamSlider {
                width: parent.width
                key: "seg.speed"; label: "speed"
                from: 0; to: 800; unit: "px/s"; defaultValue: 220
                value: v.speed; onMoved: x => v.speed = x
                // streaks off a letter, longer as it grows
                illustration: Component {
                    ParamFrame {
                        id: f
                        ParamSegment { x: 2; y: parent.height * 0.22; width: parent.width * 0.14; height: parent.height * 0.56; on: true }
                        Repeater {
                            model: 4
                            ParamSegment {
                                required property int index
                                readonly property real len: (0.12 + f.t * 0.68) * (1 - index * 0.12)
                                x: parent.width * 0.2; y: parent.height * (0.2 + index * 0.17)
                                width: parent.width * 0.78; height: Math.max(2, Math.round(parent.height * 0.08))
                                on: true
                                path: "M0 0 L" + (len * 100).toFixed(1) + " 0 L" + (len * 100).toFixed(1) + " 100 L0 100 Z"
                            }
                        }
                    }
                }
            }
            ParamSlider {
                width: parent.width
                key: "seg.angle"; label: "direction (0 right, 90 down, 270 up)"
                from: 0; to: 360; unit: "°"; defaultValue: 355
                value: v.angle; onMoved: x => v.angle = x
                // an arrow turning, the four ways printed round it
                illustration: Component {
                    ParamFrame {
                        id: f
                        readonly property real size: Math.min(width, height) * 0.9
                        Repeater {
                            model: 4
                            ParamSegment {
                                required property int index
                                width: Math.max(2, Math.round(f.size * 0.09)); height: width
                                x: f.width / 2 + Math.cos(index * Math.PI / 2) * f.size * 0.48 - width / 2
                                y: f.height / 2 + Math.sin(index * Math.PI / 2) * f.size * 0.48 - height / 2
                                on: Math.round(f.t * 4) % 4 === index
                            }
                        }
                        ParamSegment {
                            width: f.size * 0.74; height: f.size * 0.42
                            x: (f.width - width) / 2; y: (f.height - height) / 2
                            rotation: f.t * 360
                            on: true
                            path: "M0 36 L56 36 L56 6 L100 50 L56 94 L56 64 L0 64 Z"
                        }
                    }
                }
            }
            ParamSlider {
                width: parent.width
                key: "seg.turbulence"; label: "turbulence"
                from: 0; to: 600; defaultValue: 80
                value: v.turbulence; onMoved: x => v.turbulence = x
                // drift lines, wavier as it grows
                illustration: Component {
                    ParamFrame {
                        id: f
                        Repeater {
                            model: 2
                            ParamSegment {
                                required property int index
                                x: 2; y: parent.height * (0.08 + index * 0.46); width: parent.width - 4; height: parent.height * 0.4
                                on: true
                                stroke: Math.max(2, Theme.s(2))
                                path: {
                                    const a = 3 + f.t * 44, pts = []
                                    for (let i = 0; i <= 24; ++i) pts.push((i ? "L" : "M") + (i * 100 / 24).toFixed(1) + " " + (50 + a * Math.sin(i * 0.9 + index * 1.7)).toFixed(1))
                                    return pts.join(" ")
                                }
                            }
                        }
                    }
                }
            }
            ParamSlider {
                width: parent.width
                key: "seg.friction"; label: "friction"
                from: 0; to: 5; stepSize: 0.01; defaultValue: 0.6
                value: v.friction; onMoved: x => v.friction = x
            }
            ParamSlider {
                width: parent.width
                key: "seg.life"; label: "life"
                from: 200; to: 10000; stepSize: 50; unit: "ms"; defaultValue: 3200
                value: v.life; onMoved: x => v.life = x
            }
        }

        ParamSection {
            width: parent.width
            title: "Dust: how it looks"
            ParamSlider {
                width: parent.width
                key: "seg.size"; label: "speck size"
                from: 1; to: 60; stepSize: 0.5; unit: "px"; defaultValue: 13
                value: v.size; onMoved: x => v.size = x
                // three specks, growing
                illustration: Component {
                    ParamFrame {
                        id: f
                        Repeater {
                            model: 3
                            ParamSegment {
                                required property int index
                                readonly property real d: Math.max(2, Math.round(f.height * (0.1 + f.t * 0.5) * (1 - index * 0.2)))
                                round: true
                                width: d; height: d
                                x: f.width * (0.2 + index * 0.3) - d / 2
                                y: f.height * (index === 1 ? 0.36 : 0.62) - d / 2
                                on: true
                            }
                        }
                    }
                }
            }
        }

        ParamSection {
            width: parent.width
            title: "Timing (plain: a number says it best)"
            ParamSlider { width: parent.width; key: "seg.gap"; label: "empty, before the reveal"; from: 0; to: 5000; stepSize: 50; unit: "ms"; defaultValue: 1200; value: v.gapMs; onMoved: x => v.gapMs = x }
            ParamSlider { width: parent.width; key: "seg.reveal"; label: "reveal"; from: 300; to: 8000; stepSize: 50; unit: "ms"; defaultValue: 2800; value: v.revealMs; onMoved: x => v.revealMs = x }
            ParamSlider { width: parent.width; key: "seg.hide"; label: "hide"; from: 300; to: 8000; stepSize: 50; unit: "ms"; defaultValue: 2200; value: v.hideMs; onMoved: x => v.hideMs = x }
        }
    }
}
