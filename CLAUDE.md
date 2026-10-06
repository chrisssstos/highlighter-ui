# ParamKit: notes for Claude

This is Christos's personal control-panel kit for Qt Quick (QML) apps. When
asked to build or restyle a params / tuning / control panel in a Qt project,
use these controls rather than stock `QtQuick.Controls` sliders and checkboxes.

## Applying it to a project

1. Link the module. In the app's CMakeLists.txt:
   `add_subdirectory(<path>/param-kit/ParamKit ${CMAKE_BINARY_DIR}/ParamKit)`
   and `target_link_libraries(<app> PRIVATE ParamKitplugin)`. If the project
   should not depend on this folder's location, copy `ParamKit/` into the
   project instead (ask which they want).
2. In the panel's QML, `import ParamKit`. Swap stock controls for kit ones:
   - `Slider` + label + value text → `ParamSlider`
   - `CheckBox` → `ParamCheck` (or `ParamToggle`)
   - preset buttons → `ParamChoice`
   - section headings → `ParamHeading`, collapsible sections → `ParamGroup`
   - paste-into-TOML blocks → `ParamCode`
   - the scrolling column → `ParamPage`
   - see "What goes where" below for sections, grids and meters
3. Keep the project's own setting plumbing. Value controls mirror Qt's
   Slider: bind `value`, write back in `onMoved: v => ...`. Watch for
   settings reloads the same way the old code did.
4. Map ranges carefully: a centred range (−400..400 "from centre") gets
   `origin: 0`; a value that must not go below 0 gets `limitFrom: 0`; a
   genuine hard maximum gets `limitTo`. Give a `defaultValue` when the
   installed default is known, so double-click resets.
5. Scale: if the window scales itself for DPI (an app's own `ui` scale), set
   `Theme.scale` to it once instead of multiplying sizes.
6. Every kit control needs `width: parent.width` inside a Column, ParamPage
   or ParamGroup. Never bind a width to a Row's width (that makes a binding
   loop).

## What goes where (only where appropriate)

- **Sections and groups.** Use `ParamSection` (always open) for each thing on
  screen a run of controls tunes (the signage card, the call to action). Use
  `ParamGroup` (folding) only when there are enough sections that some
  should fold away, or when only one at a time makes sense (failure
  factors, "one open at a time"). Use `ParamHeading` for a light label over
  a few controls that don't need a box. Nest at most one group inside
  another.
- **Grids.** Use `ParamGrid` only for runs of short, alike controls: knobs,
  checks and toggles, small gauges. Sliders go in a grid only with a big
  `minColumnWidth` (about 300), so they pair up on a wide panel and stack on
  a narrow one. Never put a long-labelled slider in a narrow column. Don't
  grid a mix of control types, and don't grid one or two controls.
- **Meters.** `ParamMeter`, `ParamGauge` and `ParamLevel` are read-only and
  only for values the app reports live: the guess right now, load, fps, a
  sound's level. Never use one to show a setting that has its own slider or
  knob. Use a gauge only when there's a safe range and a "too much"
  (`warnAt`); a level for sound or signal; a plain meter for everything
  else. Gather live readouts into one section (e.g. "Running") rather than
  scattering them, unless one belongs to a section's own visual (the guess
  inside the factor it drives).

## Working on the kit itself

- Run `run-gallery.bat` to see it. Pass `-- --shot=<png>` (and
  `--scroll=<px>`) to save a screenshot and quit, which is useful for checking
  a change without clicking.
- `tests/check.qml` checks the value logic headlessly
  (`qml.exe -I . tests/check.qml`; set `QT_FORCE_STDERR_LOGGING=1` to see its
  output). `tests/tst_editing.qml` drives the value box with real clicks and
  keys (`qmltestrunner.exe -import . -input tests/tst_editing.qml`).
  `tests/build-check.bat` proves the CMake module compiles.
- Every new control goes in `ParamKit/qmldir`, `ParamKit/CMakeLists.txt` and
  the gallery, with its awkward states shown.
- `ParamArrow` (a Shape) must keep an explicit width and height; an implicit
  size collapses it in compiled builds.
- Colours, sizes and the font live in `Theme.qml` only. Write `Theme.s(px)`
  for every size, so `scale` works.
