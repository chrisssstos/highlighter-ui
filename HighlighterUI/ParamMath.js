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

// A curve through points { t, v } (t rising, 0..1) at t: straight lines
// between them, or (smooth) a monotone cubic through them (Fritsch-Carlson),
// which bends smoothly but never overshoots a point, so a curve kept within
// 0..1 stays within it. Before the first point and after the last, their v.
function curveAt(p, t, smooth) {
    const n = p ? p.length : 0
    if (!n) return t
    if (t <= p[0].t) return p[0].v
    if (t >= p[n - 1].t) return p[n - 1].v
    let i = 1
    while (i < n - 1 && t > p[i].t) i++
    const a = p[i - 1], b = p[i], h = b.t - a.t
    if (h <= 0) return b.v
    const s = (t - a.t) / h
    if (!smooth || n < 3) return a.v + (b.v - a.v) * s
    // the slopes between points, then a tangent at each
    const d = [], m = []
    for (let k = 0; k < n - 1; k++) {
        const w = p[k + 1].t - p[k].t
        d.push(w > 0 ? (p[k + 1].v - p[k].v) / w : 0)
    }
    m.push(d[0])
    for (let k = 1; k < n - 1; k++) m.push(d[k - 1] * d[k] <= 0 ? 0 : (d[k - 1] + d[k]) / 2)
    m.push(d[n - 2])
    for (let k = 0; k < n - 1; k++) {
        if (d[k] === 0) { m[k] = 0; m[k + 1] = 0; continue }
        const x = m[k] / d[k], y = m[k + 1] / d[k], r = x * x + y * y
        if (r > 9) { const tau = 3 / Math.sqrt(r); m[k] = tau * x * d[k]; m[k + 1] = tau * y * d[k] }
    }
    const s2 = s * s, s3 = s2 * s
    return (2 * s3 - 3 * s2 + 1) * a.v + (s3 - 2 * s2 + s) * h * m[i - 1]
         + (-2 * s3 + 3 * s2) * b.v + (s3 - s2) * h * m[i]
}
