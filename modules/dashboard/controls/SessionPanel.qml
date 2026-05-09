pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var visibilities

    readonly property string title: qsTr("Session")
    readonly property real minPanelWidth: 720

    implicitWidth: Math.max(contentLayout.implicitWidth, minPanelWidth)
    implicitHeight: contentLayout.implicitHeight

    function dismissAnd(action): void {
        if (root.visibilities)
            root.visibilities.dashboard = false;
        action();
    }

    ColumnLayout {
        id: contentLayout

        anchors.fill: parent
        spacing: Tokens.spacing.large

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: actionsLayout.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: actionsLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.small

                SessionAction {
                    Layout.fillWidth: true
                    icon: "lock"
                    text: qsTr("Lock")
                    onClicked: root.dismissAnd(() => Quickshell.execDetached(["loginctl", "lock-session"]))
                }

                SessionAction {
                    Layout.fillWidth: true
                    icon: "bedtime"
                    text: qsTr("Sleep")
                    onClicked: root.dismissAnd(() => Quickshell.execDetached(["systemctl", "suspend"]))
                }

                SessionAction {
                    Layout.fillWidth: true
                    icon: "cached"
                    text: qsTr("Reboot")
                    accent: true
                    onClicked: root.dismissAnd(() => Quickshell.execDetached(["systemctl", "reboot"]))
                }

                SessionAction {
                    Layout.fillWidth: true
                    icon: "power_settings_new"
                    text: qsTr("Shutdown")
                    accent: true
                    onClicked: root.dismissAnd(() => Quickshell.execDetached(["systemctl", "poweroff"]))
                }
            }
        }
    }

    component SessionAction: StyledRect {
        id: btn

        property string icon
        property string text
        property bool accent: false
        signal clicked

        readonly property color baseColour: accent ? Colours.palette.m3errorContainer : Colours.palette.m3secondaryContainer
        readonly property color foreColour: accent ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSecondaryContainer

        implicitHeight: actionLayout.implicitHeight + Tokens.padding.normal * 2
        radius: Tokens.rounding.small
        color: btn.baseColour

        StateLayer {
            color: btn.foreColour
            radius: parent.radius
            onClicked: btn.clicked()
        }

        ColumnLayout {
            id: actionLayout

            anchors.centerIn: parent
            spacing: Tokens.spacing.smaller

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: btn.icon
                color: btn.foreColour
                font.pointSize: Tokens.font.size.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: btn.text
                color: btn.foreColour
                font.pointSize: Tokens.font.size.small
            }
        }
    }
}
