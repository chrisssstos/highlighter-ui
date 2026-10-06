# HighlighterUI

My control-panel look for Qt Quick apps: a dark grey page, lime fills and
values, chunky bar sliders with step arrows at the fill's edge. One QML module
(`import HighlighterUI`) that any Qt 6 project can link, so every app's tuning panel
looks and works the same.

## See it

`run-gallery.bat` opens the gallery with Qt's `qml.exe`, so there's nothing to
build. It shows every control in its normal and awkward states. The scale
picker resizes the whole kit, the swatches change the accent, and "disable everything" shows the disabled
states.

## The slider

- The lime fill grows from `origin`, which is `from` by default. Set it to 0
  for a centred range like "from screen centre".
- **◀ ▶ at the fill's edge:** click to step by 1 (Shift: by 10), hold to
  repeat, or drag them to slide as usual (Shift while dragging slides finely).
  They're always there: with no room on the bar they jump out clear of its
  end, and at a limit they grey out.
- **Min / max:** sliders start minimised: a thin bar with no arrows (click
  or drag it, or type in its box). The − / + by the
  label (next to ↺, both appear on hover) maximises one, and the panel
  remembers which ones between runs, in `highlighterui.ini` in the app's
  config folder. Give each slider a unique `key` (its setting's key) for
  that; it falls back to the label.
- **The default:** while the value is off its `defaultValue`, a dotted line
  marks where the default sits. `saveDefault()` makes the value the new
  default (call it on every slider from your "Save as defaults").
- **The bar:** click anywhere else to jump there and drag. Double-click to
  reset to `defaultValue`. The ↺ by the label also resets.
- **The value box** sits under the edge. Click it to type a value. It accepts
  the unit (`46px`) and simple sums (`40+6`). Up and Down step, Enter keeps the
  value and Esc drops it.
- **Past the ends:** the bar spans `from..to`, but the arrows and typing can go
  past it, up to `limitFrom..limitTo` (no limit by default). A full bar can
  still be nudged; it shows a notch and the ▶ sits outside the bar.
- **Keyboard:** Tab in, then use the arrow keys, PgUp/PgDn, Home/End. Enter
  starts typing and Delete resets.

The knob works the same way: drag up or right, double-click to reset, and the
value box sits between its step arrows.

## Controls

| | |
|---|---|
| `ParamSlider` | the bar slider above |
| `ParamKnob` | rotary, same value rules |
| `ParamXY` | a grid with a dot, to place something on a canvas: drag (Shift fine, Ctrl snaps), arrow keys, typed x / y, footprint and ghosts of other elements. Minimised (the default, remembered like sliders) it is the same grid as a thumbnail, x / y beside it |
| `ParamButton` | `accent`, `danger`, `checkable`, `icon` |
| `ParamToggle`, `ParamCheck` | on/off |
| `ParamChoice` | a row of options (presets 1/2, shader), wraps |
| `ParamCombo` | drop-down |
| `ParamField` | one-line text |
| `ParamMeter` | read-only live value with peak |
| `ParamGauge` | read-only half-dial with a warning zone |
| `ParamLevel` | read-only segmented level (sound, signal) |
| `ParamLight` | a small square lit while something is on (a sound playing) |
| `ParamText` | the panel's own text: a note, a status, a path, or (`caps`) a column's name over rows |
| `ParamGrid` | equal columns, as many as fit, for short alike controls |
| `ParamSection` | an always-open titled section (no bracket: only what folds has one) |
| `ParamHeading` | small caps heading with a rule |
| `ParamGroup` | folding group in a lime bracket |
| `ParamCode` | copyable block (TOML to paste), folded to its title and a Copy button until opened |
| `ParamPage` | scrolling column on the page colour |
| `ParamSwatches` | a row of colour swatches (a colour setting, or the accent) |
| `PanelMemory` | remembers which sliders are maximised |
| `Theme` | colours, sizes (`groupInset`: where a folding group's controls start, `sectionInset`: a section's, either side), font, `scale`, `compact`, `accent`, `slidersStartMinimised` |

`Theme.compact` shrinks knobs and spacing; `Theme.slidersStartMinimised`
(on) is whether sliders the user hasn't maximised start thin.
`Theme.industrial` (on) is the analogue look: brushed, bevelled plates with
screws behind sections and groups, a grained page, inset grooves for the
bars, LCD value boxes, a scope screen for the XY pad, knurled knobs with a
pointer line, brushed buttons with an LED when they stay down, and stamped
titles. Off gives the flat look. `ParamPlate`, `ParamScrew` and `ParamBevel`
are the pieces, for a panel's own surfaces.
`Theme.smooth` (off) turns antialiasing back on for arrows, knobs, gauges and
round shapes; off gives the kit its hard, nearest-neighbour edges.
`Theme.accent` recolours everything; the darker shades follow it, and
`Theme.accents` lists ones that read well on the grey. A window that declares
its own `property color accent` draws its controls in that colour instead, so
two panels in one app can look apart:

```qml
Window { property color accent: "#ff79c6"   // this panel in pink
    ParamPage { ... } }
```

CLAUDE.md says when each layout piece and meter is the right one.

Value controls behave like Qt's `Slider`: bind `value`, write back in
`onMoved`:

```qml
ParamSlider {
    width: parent.width
    label: "ring, from screen centre"; unit: " mm"
    from: -400; to: 400; origin: 0; defaultValue: 0
    value: Tuning.read("fire.ringMm")
    onMoved: v => Tuning.set("fire.ringMm", v)
}
```

## Use it in a project

The repo is private: https://github.com/chrisssstos/highlighter-ui

Either add it as a submodule (updates come with `git submodule update --remote`):

```
git submodule add https://github.com/chrisssstos/highlighter-ui external/highlighter-ui
```

or copy the `HighlighterUI/` folder into the project (for client work whose
builds shouldn't need access to this repo). Then:

```cmake
add_subdirectory(<path>/highlighter-ui/HighlighterUI ${CMAKE_BINARY_DIR}/HighlighterUI)
target_link_libraries(<app> PRIVATE HighlighterUIplugin)
```

Then `import HighlighterUI` in QML. `tests/build-check.bat` builds the gallery as
a compiled app this way, to prove the module works.

It uses Segoe UI and Consolas, which every Windows PC has, so nothing needs
bundling.
