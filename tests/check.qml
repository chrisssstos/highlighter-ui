import QtQuick
import ParamKit
import "../ParamKit/ParamMath.js" as PM

Item {
    ParamSlider { id: s; from: 0; to: 46; limitFrom: 0; value: 46; unit: "px" }
    ParamKnob { id: k; from: -1; to: 1; stepSize: 0.001; value: 0 }
    Component.onCompleted: {
        const out = []
        out.push("parse 46px=" + PM.parse("46px", "px"), "40+6=" + PM.parse("40+6", ""), "−3=" + PM.parse("−3", ""), "junk=" + PM.parse("alert(1)", ""), "1/3=" + PM.parse("1/3", ""))
        out.push("fmt -0.0=" + PM.format(-0.0001, 2), "snap .1+.2=" + PM.snap(0.1 + 0.2, 0.01, 0))
        s.step(+1, false); out.push("46+1=" + s.value)
        s.setValue(-5); out.push("clamp -5=" + s.value)
        s.step(-1, false); out.push("0-1=" + s.value + " canDown=" + s.canDown)
        k.step(+1, true); out.push("knob +10 steps=" + k.value)
        console.warn(out.join(" | "))
        Qt.quit()
    }
}
