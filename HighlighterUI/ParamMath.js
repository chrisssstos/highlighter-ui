.pragma library

// Number helpers the value controls share.

//! Decimals to show for a step: 1 -> 0, 0.1 -> 1, 0.05 -> 2.
function decimalsFor(step) {
    if (!(step > 0)) return 2
    const s = String(step)
    const i = s.indexOf(".")
    if (s.indexOf("e-") >= 0) return Number(s.split("e-")[1])
    return i < 0 ? 0 : s.length - i - 1
}

//! Snaps v onto the grid of step counted from base, and drops float noise.
function snap(v, step, base) {
    if (!(step > 0)) return v
    const n = Math.round((v - base) / step)
    return Number((base + n * step).toFixed(decimalsFor(step) + 2))
}

function clamp(v, lo, hi) { return Math.min(hi, Math.max(lo, v)) }

function format(v, decimals) {
    if (!isFinite(v)) return "-"
    let t = v.toFixed(decimals)
    if (/^-0(\.0+)?$/.test(t)) t = t.substring(1)   // no "-0"
    return t.replace("-", "−")                  // a true minus, as wide as +
}

//! A typed value: a number, maybe with its unit or simple arithmetic
//! ("46px", "40+6", "1/3", "-(2*4)"). NaN when it can't be read.
function parse(text, unit) {
    let t = String(text).trim()
    const u = String(unit || "").trim()
    if (u.length && t.endsWith(u)) t = t.substring(0, t.length - u.length)
    t = t.replace(/−/g, "-").replace(/,/g, ".").replace(/\s+/g, "")
    if (!t.length || !/^[0-9+\-*/.()]+$/.test(t)) return NaN
    try {
        const v = Function('"use strict"; return (' + t + ')')()
        return typeof v === "number" && isFinite(v) ? v : NaN
    } catch (e) {
        return NaN
    }
}
