import QtQuick

/// A faceplate: the raised colour, and in the industrial look a satin
/// powder-coat (soft light falling off top to bottom, a fine grain), a crisp
/// edge, a shadow cast on what is behind, and a screw in each corner (two,
/// mid-height, on a slim plate). Flat otherwise.
Item {
    id: plate

    property color color: Theme.raised
    property bool screws: true
    //! Where the screws sit in from the corners.
    property int screwInset: Theme.s(5)
    //! The left screws' inset, if they have to clear something.
    property int screwInsetLeft: screwInset
    //! The shadow it casts (industrial), down and a little right.
    property bool castShadow: true

    // its shadow on whatever it is mounted on
    Rectangle {
        visible: Theme.industrial && plate.castShadow
        x: Theme.s(1); y: Theme.s(3)
        width: parent.width; height: parent.height
        color: Qt.rgba(0, 0, 0, 0.5)
    }
    Rectangle {
        id: face
        anchors.fill: parent
        color: plate.color
        // satin: a little light at the top, falling off down the plate
        gradient: Theme.industrial ? sheen : null
        Gradient {
            id: sheen
            GradientStop { position: 0; color: Qt.lighter(plate.color, 1.16) }
            GradientStop { position: 0.12; color: Qt.lighter(plate.color, 1.06) }
            GradientStop { position: 1; color: Qt.darker(plate.color, 1.10) }
        }
    }
    Image {
        anchors.fill: parent
        visible: Theme.industrial
        source: "textures/powder.png"
        fillMode: Image.Tile
        smooth: false
    }
    // a crisp edge: a dark outline, a light line just inside the top and left
    Rectangle {
        anchors.fill: parent
        visible: Theme.industrial
        color: "transparent"
        border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.6)
    }
    ParamBevel { anchors.fill: parent; anchors.margins: 1; visible: Theme.industrial; light: 0.14; dark: 0.18 }

    Repeater {
        readonly property bool slim: plate.height < Theme.s(56)
        model: Theme.industrial && plate.screws && plate.width > Theme.s(60) ? (slim ? 2 : 4) : 0
        ParamScrew {
            required property int index
            readonly property bool slim: plate.height < Theme.s(56)
            x: index % 2 === 0 ? plate.screwInsetLeft : plate.width - width - plate.screwInset
            y: slim ? Math.round((plate.height - height) / 2)
                    : index < 2 ? plate.screwInset : plate.height - height - plate.screwInset
            angle: [28, 112, 71, 154][index]
        }
    }
}
