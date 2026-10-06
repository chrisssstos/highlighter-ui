import QtQuick

/// Lays short controls out in as many equal columns as fit (at least
/// minColumnWidth each, at most maxColumns), one column on a narrow panel.
/// It sets its children's widths itself. Use it for runs of short, alike
/// controls: knobs, toggles, short sliders. Not for a mix of long and short.
Grid {
    id: grid

    property int minColumnWidth: Theme.s(220)
    property int maxColumns: 4

    columns: Math.max(1, Math.min(maxColumns, Math.floor((width + columnSpacing) / (minColumnWidth + columnSpacing))))
    columnSpacing: Theme.s(24)
    rowSpacing: Theme.controlGap

    readonly property real cellWidth: (width - (columns - 1) * columnSpacing) / columns
    function fit() {
        for (let i = 0; i < children.length; ++i)
            children[i].width = cellWidth
    }
    onCellWidthChanged: fit()
    onChildrenChanged: fit()
    Component.onCompleted: fit()
}
