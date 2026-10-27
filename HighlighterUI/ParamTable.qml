import QtQuick
import QtQuick.Controls.Basic as B
import "ParamMath.js" as PM

/// A read-only table: presets, devices, files, log lines. A grey header row
/// with the column names (a graph's title bar), then the rows on a sunken well with faint lines
/// between rows and columns; past `visibleRows` it scrolls under the header.
/// Click a row (or Up / Down) to pick it, double-click or Enter to open it.
/// For a setting with a few named options, use a ParamChoice or ParamCombo.
Item {
    id: root

    //! The accent it draws in: its window's own, if that declares one (see Theme).
    readonly property color tint: Theme.accentIn(Window.window)

    property string label: ""
    //! The columns: names ("name"), or objects { title, width, align }. A width
    //! over 1 is pixels (scaled), up to 1 a share of the table; columns with
    //! none split what's left. align: "left" (the default) or "right" (numbers).
    property var columns: []
    //! The rows, each a list of cells in column order. A cell is text, or
    //! { text, tone } to colour it: "good" (the accent), "ok" (Theme.caution),
    //! "bad" (Theme.danger), "dim" (faint) — a rating, a status.
    property var rows: []
    //! The picked row, or -1.
    property int currentRow: -1
    //! False: rows can't be picked (a plain listing).
    property bool selectable: true
    //! How many rows show before it scrolls.
    property int visibleRows: 6
    property int rowHeight: Theme.c(26, 20)
    //! Shown in the well when there are no rows.
    property string placeholder: "nothing yet"
    //! Cells in Consolas (paths, ids, hex).
    property bool mono: false

    //! A row was picked (it tells you first, as ParamChoice does).
    signal activated(int row)
    //! A row was double-clicked or Entered.
    signal opened(int row)

    function pick(i) {
        if (!root.selectable || root.rows.length === 0) return
        i = PM.clamp(i, 0, root.rows.length - 1)
        list.positionViewAtIndex(i, ListView.Contain)
        if (i === root.currentRow) return
        // Tells you first; it only picks the row itself if you didn't, so
        // currentRow bound to your own state stays bound.
        root.activated(i)
        if (root.currentRow !== i) root.currentRow = i
    }

    function colOf(c) { return typeof c === "string" ? { title: c } : c }
    function alignOf(i) { return i < root.columns.length && root.colOf(root.columns[i]).align === "right" ? Text.AlignRight : Text.AlignLeft }
    //! Each column's width in pixels; the last takes up any rounding.
    readonly property var widths: {
        const w = body.width, cols = root.columns.map(root.colOf)
        let fixed = 0, free = 0
        const out = cols.map(c => {
            if (c.width === undefined) { free++; return -1 }
            const px = c.width > 1 ? Theme.s(c.width) : Math.round(c.width * w)
            fixed += px
            return px
        })
        const share = free ? Math.max(0, Math.floor((w - fixed) / free)) : 0
        for (let i = 0; i < out.length; i++) if (out[i] < 0) out[i] = share
        if (out.length) out[out.length - 1] += w - out.reduce((a, b) => a + b, 0)
        return out
    }
    function xOf(i) { let x = 0; for (let k = 0; k < i; k++) x += root.widths[k]; return x }

    implicitWidth: Theme.s(320)
    implicitHeight: head.y + head.height + body.height
    activeFocusOnTab: root.selectable
    opacity: enabled ? 1 : 0.4

    Text {
        id: title
        visible: root.label.length > 0
        width: parent.width
        text: root.label
        elide: Text.ElideRight
        color: Theme.text
        font.family: Theme.family
        font.pixelSize: Theme.labelSize
    }

    // --- the header: the column names, in a graph's grey bar-----------------------
    Rectangle {
        id: head
        y: title.visible ? title.implicitHeight + Theme.rowGap : 0
        width: parent.width
        height: root.rowHeight
        // a graph's title bar: grey, a dark line under it
        color: Theme.panelBar
        gradient: Theme.classic ? classicBar : null
        Gradient {
            id: classicBar
            GradientStop { position: 0; color: Qt.lighter(Theme.titleBar, 1.12) }
            GradientStop { position: 0.5; color: Theme.titleBar }
            GradientStop { position: 1; color: Theme.titleBarEnd }
        }
        Rectangle { y: parent.height - 1; width: parent.width; height: 1; color: Qt.rgba(0, 0, 0, 0.3) }
        Repeater {
            model: root.columns.length
            Item {
                required property int index
                x: root.xOf(index); width: root.widths[index] ?? 0; height: head.height
                Text {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.s(8); anchors.rightMargin: Theme.s(8)
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: root.alignOf(index)
                    text: root.colOf(root.columns[index]).title ?? ""
                    elide: Text.ElideRight
                    color: Theme.text
                    font.family: Theme.family
                    font.pixelSize: Theme.titleSize
                    style: Theme.titleStyle; styleColor: Theme.titleStyleColor
                }
                // the divider before it
                Rectangle { visible: index > 0; width: 1; height: parent.height; color: Qt.rgba(0, 0, 0, 0.25) }
            }
        }
    }

    // --- the rows ------------------------------------------------------------
    Rectangle {
        id: body
        y: head.y + head.height
        width: parent.width
        height: root.visibleRows * root.rowHeight
        color: Theme.sunken
        clip: true
        border.width: root.activeFocus && !area.focusedByMouse ? 1 : 0
        border.color: root.tint
        ParamBevel { anchors.fill: parent; visible: Theme.classic; inset: true; light: 0.1; dark: 0.45 }

        readonly property color rule: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)

        // the column lines, down the whole well so an empty table still shows its grid
        Repeater {
            model: Math.max(0, root.columns.length - 1)
            Rectangle { required property int index; x: root.xOf(index + 1); width: 1; height: body.height; color: body.rule }
        }
        // and the row lines under the empty rows too
        Repeater {
            model: root.visibleRows
            Rectangle { required property int index; y: (index + 1) * root.rowHeight - 1 - (list.contentY % root.rowHeight); width: body.width; height: 1; color: body.rule }
        }

        ListView {
            id: list
            anchors.fill: parent
            model: root.rows.length
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height
            B.ScrollBar.vertical: ParamScrollBar {}
            delegate: Item {
                id: row
                required property int index
                readonly property bool on: root.selectable && index === root.currentRow
                readonly property bool hot: area.containsMouse && area.hoverRow === index
                width: list.width
                height: root.rowHeight
                Rectangle {
                    anchors.fill: parent
                    anchors.bottomMargin: 1
                    color: row.on ? Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.22)
                         : row.hot && root.selectable ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                }
                Repeater {
                    model: root.columns.length
                    Text {
                        required property int index
                        readonly property var cell: root.rows[row.index] ? root.rows[row.index][index] : undefined
                        x: root.xOf(index) + Theme.s(8)
                        width: (root.widths[index] ?? 0) - Theme.s(16)
                        height: row.height
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: root.alignOf(index)
                        readonly property bool rich: cell !== null && typeof cell === "object"
                        readonly property string tone: rich ? (cell.tone ?? "") : ""
                        text: cell === undefined || cell === null ? "" : rich ? String(cell.text ?? "") : String(cell)
                        elide: Text.ElideRight
                        color: tone === "good" ? root.tint : tone === "ok" ? Theme.caution : tone === "bad" ? Theme.danger
                             : tone === "dim" ? Theme.textFaint : row.on ? root.tint : Theme.text
                        font.family: root.mono ? Theme.mono : Theme.family
                        font.pixelSize: Theme.valueSize
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.rows.length === 0
            text: root.placeholder
            color: Theme.textFaint
            font.family: Theme.family
            font.pixelSize: Theme.smallSize
        }

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.rightMargin: Theme.s(14)   // leave the scroll bar its own clicks
            enabled: root.enabled && root.selectable
            hoverEnabled: true
            cursorShape: root.rows.length ? Qt.PointingHandCursor : Qt.ArrowCursor
            property bool focusedByMouse: true
            readonly property int hoverRow: list.indexAt(mouseX, mouseY + list.contentY)
            onPressed: m => { focusedByMouse = true; root.forceActiveFocus(Qt.MouseFocusReason) }
            onClicked: m => { const i = list.indexAt(m.x, m.y + list.contentY); if (i >= 0) root.pick(i) }
            onDoubleClicked: m => { const i = list.indexAt(m.x, m.y + list.contentY); if (i >= 0) { root.pick(i); root.opened(i) } }
            onWheel: w => w.accepted = false
        }
    }

    // a thin outline round the header and rows, as round a graph
    Rectangle { x: head.x; y: head.y; width: head.width; height: head.height + body.height; color: "transparent"; border.width: 1; border.color: Theme.panelEdge; visible: !Theme.classic }

    Keys.onUpPressed: { area.focusedByMouse = false; pick(currentRow < 0 ? 0 : currentRow - 1) }
    Keys.onDownPressed: { area.focusedByMouse = false; pick(currentRow + 1) }
    Keys.onPressed: e => {
        if (e.key === Qt.Key_Home) { pick(0); e.accepted = true }
        else if (e.key === Qt.Key_End) { pick(rows.length - 1); e.accepted = true }
        else if (e.key === Qt.Key_PageUp) { pick(currentRow - visibleRows); e.accepted = true }
        else if (e.key === Qt.Key_PageDown) { pick(currentRow + visibleRows); e.accepted = true }
        else if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter) && currentRow >= 0) { opened(currentRow); e.accepted = true }
    }
}
