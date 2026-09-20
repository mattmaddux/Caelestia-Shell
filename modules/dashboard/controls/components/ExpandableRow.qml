pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

// A touch-sized row that reveals its actions in place rather than opening
// another surface. Shared by the dashboard control panels so wifi, bluetooth
// and ethernet all behave the same way.
ColumnLayout {
    id: root

    property string icon
    property string title
    property string subtitle
    property bool accent // connected / active
    property bool expanded
    property bool busy

    default property alias content: body.data

    signal clicked

    Layout.fillWidth: true
    spacing: Tokens.spacing.small / 2

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: rowLayout.implicitHeight + Tokens.padding.normal * 2

        radius: Tokens.rounding.normal
        color: root.expanded ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

        StateLayer {
            radius: parent.radius
            onClicked: root.clicked()
        }

        RowLayout {
            id: rowLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.padding.normal
            anchors.rightMargin: Tokens.padding.normal

            spacing: Tokens.spacing.normal

            MaterialIcon {
                Layout.alignment: Qt.AlignVCenter
                visible: root.icon !== ""

                text: root.icon
                color: root.accent ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.large
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                StyledText {
                    Layout.fillWidth: true

                    text: root.title
                    color: root.accent ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    font.pointSize: Tokens.font.size.normal
                    font.weight: root.accent ? 600 : 400
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: root.subtitle !== ""

                    text: root.subtitle
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.small
                    elide: Text.ElideRight
                }
            }

            CircularIndicator {
                Layout.alignment: Qt.AlignVCenter
                visible: root.busy
                running: root.busy
                implicitSize: chevron.implicitHeight
            }

            MaterialIcon {
                id: chevron

                Layout.alignment: Qt.AlignVCenter
                visible: !root.busy

                animate: true
                text: root.expanded ? "expand_less" : "expand_more"
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    WrapperItem {
        Layout.fillWidth: true
        Layout.leftMargin: Tokens.padding.large
        Layout.preferredHeight: root.expanded ? implicitHeight : 0

        clip: true

        ColumnLayout {
            id: body

            spacing: Tokens.spacing.small / 2
        }

        Behavior on Layout.preferredHeight {
            Anim {}
        }
    }
}
