pragma ComponentBehavior: Bound

import "controls"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property string expandedTile: ""
    readonly property bool needsKeyboard: true

    readonly property real gridImplicitWidth: Math.max(grid.implicitWidth + Tokens.padding.large * 2, 900)
    readonly property real gridImplicitHeight: Math.max(grid.implicitHeight + Tokens.padding.large * 2, 240)
    readonly property real detailImplicitWidth: detailLoader.item?.implicitWidth ?? gridImplicitWidth
    readonly property real detailImplicitHeight: detailLoader.item?.implicitHeight ?? gridImplicitHeight

    implicitWidth: expandedTile === "" ? gridImplicitWidth : detailImplicitWidth
    implicitHeight: expandedTile === "" ? gridImplicitHeight : detailImplicitHeight

    function expand(id: string): void {
        root.expandedTile = id;
    }

    function collapse(): void {
        root.expandedTile = "";
    }

    Item {
        id: gridView

        anchors.fill: parent
        opacity: root.expandedTile === "" ? 1 : 0
        visible: opacity > 0
        enabled: visible

        Behavior on opacity {
            Anim {
                type: Anim.StandardSmall
            }
        }

        GridLayout {
            id: grid

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large

            columns: 5
            rowSpacing: Tokens.spacing.normal
            columnSpacing: Tokens.spacing.normal

            Tile {
                icon: "desktop_windows"
                kind: "expand"
                onClicked: root.expand("display")
            }

            Tile {
                icon: "videogame_asset"
                checked: GameMode.enabled
                onClicked: GameMode.enabled = !GameMode.enabled
            }

            Tile {
                icon: "notifications_off"
                checked: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }

            Tile {
                icon: "flight"
                checked: AirplaneMode.enabled
                onClicked: AirplaneMode.toggle()
            }
        }
    }

    Loader {
        id: detailLoader

        anchors.fill: parent
        active: root.expandedTile !== ""
        opacity: active ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.StandardSmall
            }
        }

        sourceComponent: Item {
            id: detailItem

            implicitWidth: Math.max(detailTitle.x + detailTitle.implicitWidth + Tokens.padding.normal, innerLoader.implicitWidth + Tokens.padding.large * 2)
            implicitHeight: backButton.y + backButton.implicitHeight + Tokens.spacing.normal + innerLoader.implicitHeight + Tokens.padding.large

            IconButton {
                id: backButton

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: Tokens.padding.normal
                anchors.leftMargin: Tokens.padding.normal

                icon: "arrow_back"
                type: IconButton.Tonal
                font.pointSize: Tokens.font.size.large
                padding: Tokens.padding.small
                onClicked: root.collapse()
            }

            StyledText {
                id: detailTitle

                anchors.verticalCenter: backButton.verticalCenter
                anchors.left: backButton.right
                anchors.leftMargin: Tokens.spacing.normal

                text: innerLoader.item?.title ?? ""
                font.pointSize: Tokens.font.size.large
                font.weight: 600
            }

            Loader {
                id: innerLoader

                anchors.top: backButton.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: Tokens.padding.large
                anchors.rightMargin: Tokens.padding.large
                anchors.topMargin: Tokens.spacing.normal
                anchors.bottomMargin: Tokens.padding.large

                sourceComponent: {
                    switch (root.expandedTile) {
                    case "display":
                        return displayPanel;
                    default:
                        return null;
                    }
                }
            }

            Component {
                id: displayPanel

                DisplayPanel {}
            }
        }
    }

    component Tile: IconButton {
        id: tile

        property string kind: "toggle"

        Layout.preferredWidth: 160
        Layout.preferredHeight: 96

        radius: stateLayer.pressed ? Tokens.rounding.small / 2 : internalChecked ? Tokens.rounding.small : Tokens.rounding.normal
        inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
        inactiveOnColour: Colours.palette.m3secondary
        toggle: kind === "toggle"
        label.fill: toggle && internalChecked ? 1 : 0
        font.pointSize: Tokens.font.size.extraLarge * 2
        radiusAnim.duration: Tokens.anim.durations.expressiveFastSpatial
        radiusAnim.easing: Tokens.anim.expressiveFastSpatial
    }
}
