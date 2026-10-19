import QtQuick
import QtQuick.Window
import HighlighterUI
import "../HighlighterUI/ParamMath.js" as PM

Item {
    ParamSlider { id: s; from: 0; to: 46; limitFrom: 0; value: 46; unit: "px" }
    ParamKnob { id: k; from: -1; to: 1; stepSize: 0.001; value: 0 }
    // Bound to your own state, as a panel binds them: a click must keep the binding.
    QtObject { id: state; property int pick: 0; property bool on: false; property string open: "" }
    ParamChoice { id: c; model: ["1", "2"]; currentIndex: state.pick; onActivated: i => state.pick = i }
    ParamCheck { id: ch; checked: state.on; onToggled: v => state.on = v }
    ParamGroup { id: g; title: "A"; open: state.open === "A"; onToggled: o => state.open = o ? "A" : "" }
    ParamGroup { id: free; title: "B"; open: false }
    ParamCode { id: code; text: "a\nb\nc" }
    Window { id: pink; property color accent: "#ff79c6"; ParamCheck { id: inPink } }
    Item { property color accent: "#b794ff"; Item { ParamCheck { id: inPanel } } }
    ParamSection { id: ownSection; property color accent: "#5cc8ff" }
    Component.onCompleted: {
        const out = []
        out.push("parse 46px=" + PM.parse("46px", "px"), "40+6=" + PM.parse("40+6", ""), "−3=" + PM.parse("−3", ""), "junk=" + PM.parse("alert(1)", ""), "1/3=" + PM.parse("1/3", ""))
        out.push("fmt -0.0=" + PM.format(-0.0001, 2), "snap .1+.2=" + PM.snap(0.1 + 0.2, 0.01, 0))
        s.step(+1, false); out.push("46+1=" + s.value)
        s.setValue(-5); out.push("clamp -5=" + s.value)
        s.step(-1, false); out.push("0-1=" + s.value + " canDown=" + s.canDown)
        k.step(+1, true); out.push("knob +10 steps=" + k.value)
        c.choose(1); state.pick = 0; out.push("choice still bound=" + (c.currentIndex === 0))
        ch.flip(); state.on = false; out.push("check still bound=" + (ch.checked === false))
        g.flip(); const opened = g.open; state.open = ""; out.push("group opened=" + opened + " still bound=" + (g.open === false))
        free.flip(); out.push("unbound group folds itself=" + free.open)
        out.push("code starts folded=" + !code.open + " lines=" + code.lines); code.flip(); out.push("code opens=" + code.open)
        out.push("window accent=" + (inPink.tint.toString() === "#ff79c6") + " kit accent=" + (ch.tint === Theme.accent)
                 + " panel accent=" + (inPanel.tint.toString() === "#b794ff")
                 + " section's own=" + (ownSection.tint.toString() === "#5cc8ff"))
        console.warn(out.join(" | "))
        Qt.quit()
    }
}
