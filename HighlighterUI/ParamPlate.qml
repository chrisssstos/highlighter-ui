import QtQuick

/// A metal plate behind a run of controls: the raised colour, and in the
/// industrial look a brushed texture, a bevel (light top and left, dark
/// bottom and right) and a screw in each corner. Flat otherwise.
Rectangle {
    id: plate

    property bool screws: true
    //! Where the screws sit in from the corners.
    property int screwInset: Theme.s(5)
    //! The left screws' inset, if they have to clear something (a bracket).
    property int screwInsetLeft: screwInset

    color: Theme.raised

    Image {
        anchors.fill: parent
        visible: Theme.industrial
        source: "textures/brushed.png"
        fillMode: Image.Tile
        smooth: false
        opacity: 1
    }
    ParamBevel { anchors.fill: parent; visible: Theme.industrial; light: 0.16; dark: 0.55 }
    ParamBevel { anchors.fill: parent; anchors.margins: 1; visible: Theme.industrial; light: 0.07; dark: 0.25 }

    Repeater {
        model: Theme.industrial && plate.screws && plate.width > Theme.s(60) && plate.height > Theme.s(40) ? 4 : 0
        ParamScrew {
            required property int index
            x: index % 2 === 0 ? plate.screwInsetLeft : plate.width - width - plate.screwInset
            y: index < 2 ? plate.screwInset : plate.height - height - plate.screwInset
            angle: [28, 112, 71, 154][index]
        }
    }
}
