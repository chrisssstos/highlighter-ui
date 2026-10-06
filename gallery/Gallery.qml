import QtQuick
import QtQuick.Window
import ParamKit

/// Every ParamKit control, in its ordinary and awkward states, for judging
/// the look and feel. Run with run-gallery.bat.
Window {
    id: win
    width: 1440
    height: 940
    visible: true
    color: Theme.page
    title: "ParamKit gallery"

    // "-- --shot=<file.png>": save a picture of the gallery and quit.
    Timer {
        interval: 1200
        running: Qt.application.arguments.some(a => a.startsWith("--shot="))
        onTriggered: {
            const file = Qt.application.arguments.find(a => a.startsWith("--shot=")).substring(7)
            // "--scroll=<px>": scroll every column down first
            const sc = Qt.application.arguments.find(a => a.startsWith("--scroll="))
            if (sc) for (const p of [page1, page2, inUse]) p.contentY = Math.min(Number(sc.substring(9)), Math.max(0, p.contentHeight - p.height))
            win.contentItem.grabToImage(r => { r.saveToFile(file); Qt.quit() })
        }
    }

    // --- the top bar ---------------------------------------------------------
    Rectangle {
        id: bar
        width: parent.width
        height: Theme.s(48)
        color: Theme.sunken
        Row {
            x: Theme.s(16)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.s(20)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "PARAMKIT"
                color: Theme.accent
                font.family: Theme.family
                font.pixelSize: Theme.s(17)
                font.weight: Font.Black
                font.letterSpacing: Theme.s(2)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "gallery: every control, every awkward state"
                color: Theme.textFaint
                font.family: Theme.family
                font.pixelSize: Theme.smallSize
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.s(16)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.s(16)
            Text { text: "scale"; color: Theme.textDim; font.family: Theme.family; font.pixelSize: Theme.smallSize; anchors.verticalCenter: parent.verticalCenter }
            ParamChoice {
                width: Theme.s(170)
                anchors.verticalCenter: parent.verticalCenter
                model: ["1", "1.25", "1.5", "2"]
                currentIndex: 0
                onActivated: i => Theme.scale = [1, 1.25, 1.5, 2][i]
            }
            ParamToggle {
                id: allOff
                anchors.verticalCenter: parent.verticalCenter
                text: "disable everything"
            }
        }
    }

    Row {
        y: bar.height
        width: parent.width
        height: parent.height - bar.height
        enabled: !allOff.checked

        // --- column 1: sliders ---------------------------------------------------
        ParamPage {
            id: page1
            width: parent.width / 3
            height: parent.height

            ParamHeading { width: parent.width; text: "The mockup"; note: "0..46, no lower than 0, may go past 46" }
            ParamSlider { width: parent.width; label: "Text size"; unit: "px"; from: 0; to: 46; limitFrom: 0; value: 0; defaultValue: 16 }
            ParamSlider { width: parent.width; label: "Text size (1: no room left of the edge)"; unit: "px"; from: 0; to: 46; limitFrom: 0; value: 1; defaultValue: 16 }
            ParamSlider { width: parent.width; label: "Text size"; unit: "px"; from: 0; to: 46; limitFrom: 0; value: 23; defaultValue: 16 }
            ParamSlider { width: parent.width; label: "Text size (45: no room right of the edge)"; unit: "px"; from: 0; to: 46; limitFrom: 0; limitTo: 46; value: 45; defaultValue: 16 }
            ParamSlider { width: parent.width; label: "Text size"; unit: "px"; from: 0; to: 46; limitFrom: 0; value: 46; defaultValue: 16 }
            ParamSlider { width: parent.width; label: "Text size (past the end)"; unit: "px"; from: 0; to: 46; limitFrom: 0; value: 47; defaultValue: 16 }

            ParamHeading { width: parent.width; text: "Ranges" }
            ParamSlider { width: parent.width; label: "top edge from centre (fills from 0)"; unit: " mm"; from: -400; to: 400; origin: 0; value: -300; defaultValue: 0 }
            ParamSlider { width: parent.width; label: "left edge from centre"; unit: " mm"; from: -400; to: 400; origin: 0; value: 201; defaultValue: 0 }
            ParamSlider { width: parent.width; label: "preview reach"; from: 0; to: 1; stepSize: 0.01; value: 0.5; defaultValue: 0.5 }
            ParamSlider { width: parent.width; label: "kaleidoscope blooms over (step 50)"; unit: " ms"; from: 0; to: 10000; stepSize: 50; value: 4500; defaultValue: 4500 }
            ParamSlider { width: parent.width; label: "fine: 0.001 steps"; from: 0; to: 0.1; stepSize: 0.001; value: 0.053 }
            ParamSlider { width: parent.width; label: "all below zero"; from: -10; to: -2; value: -6 }

            ParamHeading { width: parent.width; text: "Limits" }
            ParamSlider { width: parent.width; label: "hard 0..10: no arrow past either end"; from: 0; to: 10; limitFrom: 0; limitTo: 10; value: 10 }
            ParamSlider { width: parent.width; label: "may go under 0"; from: 0; to: 20; value: -3 }
            ParamSlider { width: parent.width; label: "1 of 0..1000: arrow wider than the fill"; from: 0; to: 1000; limitFrom: 0; value: 1 }
            ParamSlider { width: parent.width; label: "from = to (a range of nothing)"; from: 5; to: 5; value: 5 }

            ParamHeading { width: parent.width; text: "Awkward" }
            ParamSlider { width: parent.width; label: "turbine dimming under every visual (0 none, 1 black), a label far too long for its row"; from: 0; to: 1; stepSize: 0.01; value: 1 }
            ParamSlider { width: parent.width; label: "disabled"; from: 0; to: 100; value: 40; enabled: false }
            ParamSlider { width: Theme.s(150); label: "narrow"; unit: " mm"; from: 0; to: 900; value: 690 }
            ParamSlider { width: parent.width; label: "a big unit"; unit: " frames per second"; from: 0; to: 240; value: 60 }
            ParamSlider { width: parent.width; label: ""; from: 0; to: 100; value: 30 }
            Text { width: parent.width; wrapMode: Text.Wrap; color: Theme.textFaint; font.family: Theme.family; font.pixelSize: Theme.smallSize
                   text: "Arrows: click to step 1 (Shift 10), hold to repeat, drag to slide (Shift while dragging: fine). Bar: click to jump, double-click to reset. Box: click to type, sums allowed (40+6), Up/Down step, Esc cancels. Keyboard: Tab in, arrows / PgUp / PgDn / Home / End, Enter types, Delete resets." }
        }

        // --- column 2: knobs, buttons, toggles, choices ----------------------------
        ParamPage {
            id: page2
            width: parent.width / 3
            height: parent.height

            ParamHeading { width: parent.width; text: "Knobs" }
            Flow {
                width: parent.width
                spacing: Theme.s(10)
                ParamKnob { label: "slices"; from: 3; to: 24; value: 15; defaultValue: 12 }
                ParamKnob { label: "twist"; from: -1; to: 1; stepSize: 0.001; origin: 0; value: -0.297; defaultValue: 0 }
                ParamKnob { label: "ring ignites"; unit: " ms"; from: 0; to: 4500; stepSize: 50; value: 2500; ticks: 0 }
                ParamKnob { label: "past the end"; from: 0; to: 10; limitFrom: 0; value: 12 }
                ParamKnob { label: "disabled"; from: 0; to: 10; value: 4; enabled: false }
            }

            ParamHeading { width: parent.width; text: "Buttons" }
            Flow {
                width: parent.width
                spacing: Theme.s(6)
                ParamButton { text: "Save as defaults"; accent: true }
                ParamButton { text: "Reset to installed defaults" }
                ParamButton { text: "Copy"; icon: "\u2398" }
                ParamButton { text: "Preview full screen"; checkable: true }
                ParamButton { text: "Delete preset"; danger: true }
                ParamButton { text: "Disabled"; enabled: false }
                ParamButton { text: "Disabled accent"; accent: true; enabled: false }
            }
            Flow {
                width: parent.width
                spacing: 1
                ParamButton { icon: "\u25AE\u25C0"; text: "" ; implicitWidth: Theme.s(34) }
                ParamButton { icon: "\u25B6"; text: "Play"; checkable: true; checked: true }
                ParamButton { icon: "\u275A\u275A"; text: "Pause" }
                ParamButton { icon: "\u25A0"; text: "Stop" }
                ParamButton { icon: "\u25B6\u25AE"; text: ""; implicitWidth: Theme.s(34) }
            }
            ParamButton { width: parent.width; text: "A full-width button with a label long enough to need the room" }

            ParamHeading { width: parent.width; text: "On / off" }
            Flow {
                width: parent.width
                spacing: Theme.s(18)
                ParamCheck { text: "Tiles" }
                ParamCheck { text: "Outline LED tiles"; checked: true }
                ParamCheck { text: "Disabled"; enabled: false; checked: true }
            }
            Flow {
                width: parent.width
                spacing: Theme.s(18)
                ParamToggle { text: "Preview full screen" }
                ParamToggle { text: "Sound"; checked: true }
                ParamToggle { text: "Disabled"; enabled: false }
            }
            ParamCheck { width: Theme.s(200); text: "a check with a label far too long to fit in its width" }

            ParamHeading { width: parent.width; text: "Choices" }
            ParamChoice { width: parent.width; label: "overall preset"; model: ["1", "2"]; currentIndex: 0; cellHeight: Theme.s(44); cellMinWidth: Theme.s(44) }
            ParamChoice { width: parent.width; label: "shader"; model: ["ring", "kaleidoscope", "flood", "explosion"]; currentIndex: 1 }
            ParamChoice { width: parent.width; label: "many (wraps)"; model: ["1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20"]; currentIndex: 6 }
            ParamCombo { width: parent.width; label: "blend mode"; model: ["normal", "add", "screen", "multiply", "overlay", "difference"]; currentIndex: 1 }
            ParamCombo { width: parent.width; label: "a long list (scrolls)"; model: 40; currentIndex: 12 }
            ParamCombo { width: parent.width; label: "disabled"; model: ["one", "two"]; enabled: false }

            ParamHeading { width: parent.width; text: "Text" }
            ParamField { width: parent.width; label: "settings file"; mono: true; text: "C:/Users/someone/settings/MyApp/app_settings.toml" }
            ParamField { width: parent.width; label: "preset name"; placeholder: "untitled preset" }
        }

        // --- column 3: a panel in use -----------------------------------------------
        ParamPage {
            id: inUse
            width: parent.width / 3
            height: parent.height

            QtObject {
                id: fire
                property int overall: 0
                property real reachMin: 0.053
                property real reachMax: 0.68
                property real speed: 0.3
                property real distortion: 0.812
                property int slices: 15
                property real twist: -0.297
            }
            property string openGroup: "fire"
            property real guess: 0
            NumberAnimation on guess { from: 0; to: 1; duration: 2600; loops: Animation.Infinite; easing.type: Easing.InOutSine }

            ParamHeading { width: parent.width; text: "Failure factor visuals"; note: "one open at a time" }
            ParamGroup {
                width: parent.width; title: "Mechanical"
                open: inUse.openGroup === "mechanical"
                onToggled: o => inUse.openGroup = o ? "mechanical" : ""
                ParamSlider { width: parent.width; label: "turbine dims over"; unit: " ms"; from: 0; to: 5000; stepSize: 50; value: 900 }
                ParamSlider { width: parent.width; label: "shake"; from: 0; to: 1; stepSize: 0.01; value: 0.4 }
            }
            ParamGroup {
                width: parent.width; title: "Fire"; note: "preset 2"
                open: inUse.openGroup === "fire"
                onToggled: o => inUse.openGroup = o ? "fire" : ""
                ParamChoice { width: parent.width; label: "overall preset"; model: ["1", "2"]; currentIndex: fire.overall; onActivated: i => fire.overall = i; cellHeight: Theme.s(40); cellMinWidth: Theme.s(40) }
                ParamMeter { width: parent.width; label: "guess, live"; value: inUse.guess }
                ParamSlider { width: parent.width; label: "reach min"; from: 0; to: 1; stepSize: 0.001; value: fire.reachMin; onMoved: v => fire.reachMin = v; defaultValue: 0.05 }
                ParamSlider { width: parent.width; label: "reach max"; from: 0; to: 1; stepSize: 0.001; value: fire.reachMax; onMoved: v => fire.reachMax = v; defaultValue: 0.7 }
                ParamSlider { width: parent.width; label: "speed"; from: 0; to: 2; stepSize: 0.01; value: fire.speed; onMoved: v => fire.speed = v; defaultValue: 0.3 }
                ParamSlider { width: parent.width; label: "distortion"; from: 0; to: 1; stepSize: 0.001; value: fire.distortion; onMoved: v => fire.distortion = v }
                Flow {
                    width: parent.width
                    spacing: Theme.s(10)
                    ParamKnob { label: "slices"; from: 3; to: 24; value: fire.slices; onMoved: v => fire.slices = v; defaultValue: 12 }
                    ParamKnob { label: "twist"; from: -1; to: 1; stepSize: 0.001; origin: 0; value: fire.twist; onMoved: v => fire.twist = v; defaultValue: 0 }
                }
                ParamGroup {
                    width: parent.width; title: "Kaleidoscope"; note: "nested"; open: false
                    ParamSlider { width: parent.width; label: "strength"; from: 0; to: 1; stepSize: 0.01; value: 0.9 }
                    ParamSlider { width: parent.width; label: "spin speed"; from: 0; to: 20; stepSize: 0.01; value: 7.03 }
                }
            }
            ParamGroup {
                width: parent.width; title: "Flood"
                open: inUse.openGroup === "flood"
                onToggled: o => inUse.openGroup = o ? "flood" : ""
                ParamSlider { width: parent.width; label: "water line"; unit: " mm"; from: -400; to: 400; origin: 0; value: -120 }
            }
            ParamGroup {
                width: parent.width; title: "Explosion (empty)"
                open: inUse.openGroup === "explosion"
                onToggled: o => inUse.openGroup = o ? "explosion" : ""
            }

            ParamCode {
                width: parent.width
                title: "Fire values (paste into settings/app_settings.toml)"
                text: "[fire]\noverall = " + (fire.overall + 1)
                    + "\n\n[fire.preset2]\nreachMin = " + fire.reachMin
                    + "\nreachMax = " + fire.reachMax
                    + "\nspeed = " + fire.speed
                    + "\ndistortion = " + fire.distortion
                    + "\n\n[fire.kaleidoscope.preset2]\nslices = " + fire.slices
                    + "\ntwist = " + fire.twist
            }

            ParamHeading { width: parent.width; text: "Defaults on this machine" }
            Text { width: parent.width; wrapMode: Text.Wrap; color: Theme.textDim; font.family: Theme.family; font.pixelSize: Theme.labelSize
                   text: "Changes here last until the app restarts. Save them to make them this machine's defaults." }
            Flow {
                width: parent.width
                spacing: Theme.s(6)
                ParamButton { text: "Save as defaults"; accent: true }
                ParamButton { text: "Reset to installed defaults" }
            }
        }
    }
}
