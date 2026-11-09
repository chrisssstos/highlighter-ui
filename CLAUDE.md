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
   settings reloads the same way the old code did. Checks, toggles, checkable
   buttons, choices and groups tell you first and only change themselves if you didn't, so
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
6. Glow: `Theme.glow = true` makes whatever is lit glow in its colour
   (`ParamGlow` behind it; needs Qt 6.9+). Off by default; the gallery's top
   bar has a toggle for it. A new control's lit part gets a `ParamGlow` too.
7. Accent and size: set `Theme.accent` once if the project wants a colour
   other than the lime, and `Theme.compact = true` for a dense panel.
   Two panels that should look apart: give one window, or the item holding
   one panel's controls, its own `property color accent` (Theme.accentAt).
   Don't recolour controls one by one.
8. Scale: if the window scales itself for DPI (an app's own `ui` scale), set
   `Theme.scale` to it once instead of multiplying sizes.
9. Every kit control needs `width: parent.width` inside a Column, ParamPage
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
- **Animation.** Every slider has an animate mark (a moving ball) by its label;
  it opens a `ParamAnimator` under the bar: a range to sweep (drag its
  handles or the range), back / pause / play, seconds per pass (typed, or Up / Down),
  and loop, bounce or play once and hold.
  Its strip lines the range up under the bar; the pencil opens a graph under
  it shows the envelope (`points`, { t, v } each 0..1): time across, the
  value up, labelled with the range's two values.
  It sets the value as the user would, so the app's `onMoved` sees it;
  grabbing the bar pauses it. Off for sliders inside other controls
  (`animatable` follows `sizeToggle`); set `animatable: false` where a
  setting must never move by itself.
- **Curves.** Use `ParamCurve` for a setting that is a shape over time: an
  easing, a motor's run, a fade (points { t, v }, each 0..1). Bind `points`
  to the setting and write back in `onMoved`; give `defaultPoints` (its
  Reset button goes back to them), `duration` when time is seconds (the
  readout then says where a hovered point is in seconds), name the ends
  (`fromLabel` / `toLabel`, `startLabel` / `endLabel`) and, when something
  follows the curve live, its `position`. Any control that drags inside a
  ParamPage needs `preventStealing: true` on its MouseArea, or the page
  scrolls under the drag. `smooth` (on) bends through the
  points without overshooting; the app works the value out with the same
  maths, `curveAt(points, t, smooth)` in ParamMath.js (copy it if the app
  can't import it). Not for a live reading (that's a `ParamGraph`).
  Every editable graph in the kit (ParamCurve, ParamAnimator's envelope)
  edits the same way: click an empty spot to add, drag within
  `Theme.s(14)` of a point, right-click or double-click to remove, the ends
  pinned to t 0 and 1, points growing while hot, `preventStealing` on.
  `tests/tst_curve.qml` drives it with the mouse inside a ParamPage; a new
  editable graph gets the same tests.
- **Tables.** Use `ParamTable` for read-only rows the app lists (presets,
  devices, files, a log), picked with `currentRow` / `onActivated` and opened
  with `onOpened`. Not for a setting with a few named options (that's a
  `ParamChoice` or `ParamCombo`). Right-align number columns
  (`align: "right"`). A cell can be `{ text, tone }` to colour a rating or a
  status: "good", "ok", "bad", "dim".
- **Meters.** `ParamMeter`, `ParamGauge` and `ParamLevel` are read-only and
  only for values the app reports live: the guess right now, load, fps, a
  sound's level. Never use one to show a setting that has its own slider or
  knob. Use a gauge only when there's a safe range and a "too much"
  (`warnAt`); a level for sound or signal; a plain meter for everything
  else. Use a `ParamGraph` for a live value whose history matters (fps,
  frame time, load, memory over the last minutes): feed it with `add(v)` on
  a timer, give it a `mark` for a budget and `warnAt` for too much. A
  reading that jumps (by `jumpAt` of the scale) flashes it for a moment,
  blue the good way and red the bad way: set `better` (1 higher is better,
  like fps; -1 lower, like load or frame time), so a setting changed
  elsewhere shows which graphs it moved and whether for the better. When
  there is nothing to read for a while (a video's rate with no video on
  show), `add(NaN)`: the line breaks there and the readout shows
  `noValueText` (a dash), rather than a 0 that would read as a collapse.
  Beside a `ParamTable` of results, bind each graph's `highlighted` to its
  row being the table's `currentRow`, so a picked row shows its graph. Gather
  live readouts into one section (e.g. "Running") rather than
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
- A slider can carry an illustration (ParamFrames above its bar, maximised
  only): `pattern` for a dot matrix, or `illustration`, a ParamFrame Component
  of ParamSegments (blocks, dots or SVG paths, faint when off, lit when on).
  Only where a picture explains the setting; timing and plain numbers stay bare.
- Draw with Shapes (GeometryRenderer when `!Theme.smooth`), not Canvas: a
  Canvas always antialiases, and the kit's look is hard-edged.
- QML property names can't start with a capital, and `z` is taken (Item.z).
- `ParamArrow` (a Shape) must keep an explicit width and height; an implicit
  size collapses it in compiled builds.
- Gallery screenshot flags (after `--`): `--shot=<png>`, `--scroll=<px>`,
  `--scale=<n>`, `--compact`, `--accent=<#hex>`, `--glow`, `--mode=<dark|light>`
  (the hardware skin's mode), `--second` (also shoots the second panel).
- In qmltestrunner, a double-click is `mouseDoubleClickSequence`.
- Skins (`Theme.skin`: "flat", the default; "classic", shown as "old FL
  studio", only when asked for; "hardware", the look beater uses: faceplate,
  dark screens, glow on what's lit, reflective LCDs via ParamLCD)
  are drawn on top of the flat look: every classic touch is a
  `visible: Theme.classic` layer or a Theme colour that follows the skin, so
  "flat" must stay the plain look unchanged. A new control needs its classic
  touches (outline, bevel, LCD, gradient) like its neighbours. Use
  `ParamPlate` for a raised surface and `ParamBevel` (inset for sunk things);
  textures are in `HighlighterUI/textures` (RESOURCES in CMake). Gallery:
  `--skin=<flat|classic>` to shoot a skin (`--flat` still works). Build and
  shoot new work in flat.
  Assets are rendered by `tools/render_assets.py`; never take graphics
  from commercial plugins. Any new asset: own render (or CC0), listed in
  `textures/CREDITS.txt`.
- Hardware skin (`Theme.mode` "dark", the default, or "light"): rounded
  corners everywhere (`Theme.radius`; give every new surface it), screens
  always dark (`Theme.screenFill`) with `Theme.screenText` / `screenDim` /
  `screenFaint` on them, never `Theme.text` (that is dark ink in light
  mode). Accent text or thin lines straight on the faceplate or a key go
  through `Theme.onPanel()`; lit fills through `Theme.litOf()`. Shoot both
  modes: nothing dark on dark or light on light.
- Classic: in a panel, every run of controls belongs in a `ParamSection` or
  `ParamGroup` (each is a plugin window); loose controls on the bare page
  look wrong. Headings go between
  modules only (e.g. over a set of folding groups).
- Colours, sizes and the font live in `Theme.qml` only; sizes that change in
  compact mode use `Theme.c(full, compact)`. Write `Theme.s(px)`
  for every size, so `scale` works.

## OutputMapper (the second module)

- `OutputMapper/` maps an app's content onto its outputs, Resolume
  Advanced Output style (README has the usage). Use it, not a project's own
  warp code, whenever a projector or screen needs corner pin, warp or masks.
- Projects copy `OutputMapper/` in beside `HighlighterUI/` (it needs the kit:
  its editor is drawn with it). Changes go here first, then are copied in.
- The content renders once (a ShaderEffectSource with hideSource); every
  slice and the editor's thumbnail read that texture. Never grabToImage the
  hidden source (it renders it all again, and crashed); grab `thumbnail`.
- WarpMesh holds a raw texture pointer: feed it layer textures
  (ShaderEffectSource), never an Image (its texture is freed on each new
  source). A second reader of a texture already refreshed this frame, or
  one drawn inside a grab, sets `refreshSource: false`.
- Layer textures come vertically mirrored on D3D11: the module's
  ShaderEffectSources use `MirrorVertically` (`flipSource` if a backend
  differs).
- Its qmldir deps are DEPENDENCIES, not IMPORTS: IMPORTS re-exports QtQuick
  and shadows the app's own types (LaunchPortal's Canvas became Qt's).
- The editor's shared state (selected slice and point, view, mask mode, test
  card, show on output) lives on OutputMap, so scripts and the outputs see it.
- Outputs have ids (DisplayOutputs: "display:<screen name>"); slices keep
  the id, never an index (outputs come and go). Anything the editor follows
  across that (the viewed output) is kept by id too.
- The editor's preview grabs `thumbnail` (1/6 size) every 66 ms, one grab
  at a time: the output held 62-63 fps with it running.
- Displays are outputs whether or not the window covers them; OutputWindow
  moves the (one) output window over the displays slices use, frameless, and
  restores it when none are. Put MappedOutput straight in the window's
  content item, never inside a fit / scale view, so it is 1:1 on displays.
- Windows can't share a scene graph texture: one window per display would
  render the content once per display. Hence the one spanning window.
- An app can host MappingEditor in its own panel (LaunchPortal: the panel's
  Output tab) instead of MappingWindow; the editor carries its own Undo /
  Redo shortcuts. OutputWindow.parkWhenUnused moves the output window out of
  sight (still rendering: the preview stays live) while no slice is on a
  display; keep `ready` false until the app has put its default slices on
  displays, or it parks too early.
