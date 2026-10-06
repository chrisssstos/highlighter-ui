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

## Working on the kit itself

- Run `run-gallery.bat` to see it. Pass `-- --shot=<png>` (and
  `--scroll=<px>`) to save a screenshot and quit, which is useful for checking
  a change without clicking.
- `tests/check.qml` checks the value logic headlessly
  (`qml.exe -I . tests/check.qml`; set `QT_FORCE_STDERR_LOGGING=1` to see its
  output). `tests/build-check.bat` proves the CMake module compiles.
- Every new control goes in `ParamKit/qmldir`, `ParamKit/CMakeLists.txt` and
  the gallery, with its awkward states shown.
- `ParamArrow` (a Shape) must keep an explicit width and height; an implicit
  size collapses it in compiled builds.
- Colours, sizes and the font live in `Theme.qml` only. Write `Theme.s(px)`
  for every size, so `scale` works.
