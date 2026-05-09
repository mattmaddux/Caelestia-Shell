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

    implicitWidth: 840
    implicitHeight: 560

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
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large

            columns: 4
            rowSpacing: Tokens.spacing.normal
            columnSpacing: Tokens.spacing.normal

            Tile {
                icon: "desktop_windows"
                kind: "expand"
                expandedTo: "display"
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
            anchors.fill: parent

            IconButton {
                id: backButton

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.topMargin: Tokens.padding.normal
                anchors.leftMargin: Tokens.padding.normal

                icon: "arrow_back"
                type: IconButton.Tonal
                font.pointSize: Tokens.font.size.extraLarge
                padding: Tokens.padding.normal
                onClicked: root.collapse()
            }

            Loader {
                anchors.top: backButton.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Tokens.padding.large

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
        property string expandedTo: ""

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

        onClicked: {
            if (kind === "expand" && expandedTo !== "")
                root.expand(expandedTo);
        }
    }
}
