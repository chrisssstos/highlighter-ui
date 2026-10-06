# HighlighterUI: notes for Claude

This is Christos's personal control-panel kit for Qt Quick (QML) apps. When
asked to build or restyle a params / tuning / control panel in a Qt project,
use these controls rather than stock `QtQuick.Controls` sliders and checkboxes.

## Applying it to a project

0. Get it into the project. The repo is private on GitHub
   (https://github.com/chrisssstos/highlighter-ui). Personal projects: add
   it as a submodule (`git submodule add <url> external/highlighter-ui`).
   Client projects: ask before adding a submodule, since the
   client's build would need access to this private repo; the default there
   is to copy `HighlighterUI/` in.
1. Link the module. In the app's CMakeLists.txt:
   `add_subdirectory(<path>/highlighter-ui/HighlighterUI ${CMAKE_BINARY_DIR}/HighlighterUI)`
   and `target_link_libraries(<app> PRIVATE HighlighterUIplugin)`, with the
   path to wherever step 0 put it.
2. In the panel's QML, `import HighlighterUI`. Swap stock controls for kit ones:
   - `Slider` + label + value text → `ParamSlider`
   - `CheckBox` → `ParamCheck` (or `ParamToggle`)
   - preset buttons → `ParamChoice`
   - section headings → `ParamHeading`, collapsible sections → `ParamGroup`
   - paste-into-TOML blocks → `ParamCode`
   - notes, statuses, paths, column names over rows → `ParamText` (never a
     hand-styled `Text`); an "is playing" dot → `ParamLight`
   - the scrolling column → `ParamPage`
   - see "What goes where" below for sections, grids and meters
3. Keep the project's own setting plumbing. Value controls mirror Qt's
   Slider: bind `value`, write back in `onMoved: v => ...`. Watch for
   settings reloads the same way the old code did. Checks, toggles, choices
   and groups tell you first and only change themselves if you didn't, so
   `checked` / `currentIndex` / `open` bound to your state stay bound: bind
   them and set your state in the handler, no re-syncing needed.
   Anything a panel needs that the kit lacks goes into the kit (with the
   gallery and the checks), not into the project.
4. Give every slider `key:` its setting's key (e.g. "fire.reachMin"). The
   panel remembers which sliders the user maximised by that key; two
   sliders sharing a label would otherwise share the memory.
5. Map ranges carefully: a centred range (−400..400 "from centre") gets
   `origin: 0`; a value that must not go below 0 gets `limitFrom: 0`; a
   genuine hard maximum gets `limitTo`. Give a `defaultValue` when the
   installed default is known, so double-click resets and the dotted default
   mark shows. When the project saves defaults, set each slider's
   `defaultValue` to the saved value (or call `saveDefault()`), so the mark
   clears.
6. Accent and size: set `Theme.accent` once if the project wants a colour
   other than the lime, and `Theme.compact = true` for a dense panel.
   Two panels that should look apart: give one window its own
   `property color accent` (Theme.accentIn). Don't recolour controls one by one.
7. Scale: if the window scales itself for DPI (an app's own `ui` scale), set
   `Theme.scale` to it once instead of multiplying sizes.
8. Every kit control needs `width: parent.width` inside a Column, ParamPage
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
- **Positions.** When two settings are an element's x and y on a screen or
  canvas (e.g. "left edge / top edge from centre"), offer a `ParamXY` with
  the canvas's range (it takes its shape), `footprintWidth/Height` for the
  element's size (`footprintFromCorner` when x / y are its left and top
  edges), `ghosts` for the other elements already placed, and a
  `key` (it minimises to a thumbnail of itself and remembers being maximised).
  The pad replaces the two sliders, never sits beside them: its x / y boxes
  take typed values. A single position value stays a slider.
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
- Every new control goes in `HighlighterUI/qmldir`, `HighlighterUI/CMakeLists.txt` and
  the gallery, with its awkward states shown.
- Draw with Shapes (GeometryRenderer when `!Theme.smooth`), not Canvas: a
  Canvas always antialiases, and the kit's look is hard-edged.
- QML property names can't start with a capital, and `z` is taken (Item.z).
- `ParamArrow` (a Shape) must keep an explicit width and height; an implicit
  size collapses it in compiled builds.
- Gallery screenshot flags (after `--`): `--shot=<png>`, `--scroll=<px>`,
  `--scale=<n>`, `--compact`, `--accent=<#hex>`, `--second` (also shoots the
  second panel).
- In qmltestrunner, a double-click is `mouseDoubleClickSequence`.
- The industrial look (`Theme.industrial`) is drawn on top of the flat one:
  every industrial touch is a `visible: Theme.industrial` layer (or a colour
  choice), so switching it off must give the flat look back unchanged. Use
  `ParamPlate` for a raised surface, `ParamBevel` (inset for sunk things)
  and `ParamScrew`; textures are in `HighlighterUI/textures` (RESOURCES in
  CMake), tiled with `smooth: false`. Gallery: `--flat` to shoot it flat.
- Colours, sizes and the font live in `Theme.qml` only; sizes that change in
  compact mode use `Theme.c(full, compact)`. Write `Theme.s(px)`
  for every size, so `scale` works.
