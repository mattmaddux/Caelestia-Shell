pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property var visibilities

    readonly property string title: qsTr("Performance")
    readonly property real minPanelWidth: 720

    implicitWidth: Math.max(contentLayout.implicitWidth, minPanelWidth)
    implicitHeight: contentLayout.implicitHeight

    ColumnLayout {
        id: contentLayout

        anchors.fill: parent
        spacing: Tokens.spacing.large

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: keepAwakeLayout.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: keepAwakeLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.normal

                MaterialIcon {
                    text: "coffee"
                    color: IdleInhibitor.enabled ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.large
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Keep awake")
                        font.pointSize: Tokens.font.size.normal
                        font.weight: 600
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: IdleInhibitor.enabled ? qsTr("Idle and sleep are disabled") : qsTr("Idle timeouts active")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Tokens.font.size.small
                    }
                }

                TextButton {
                    text: qsTr("Off")
                    type: TextButton.Tonal
                    toggle: true
                    checked: !IdleInhibitor.enabled
                    onClicked: IdleInhibitor.enabled = false
                }

                TextButton {
                    text: qsTr("On")
                    type: TextButton.Tonal
                    toggle: true
                    checked: IdleInhibitor.enabled
                    onClicked: IdleInhibitor.enabled = true
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: profileLayout.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: profileLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.normal

                StyledText {
                    text: qsTr("Power Profile")
                    font.pointSize: Tokens.font.size.normal
                    font.weight: 600
                }

                StyledText {
                    visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
                    text: qsTr("Performance degraded: %1").arg(PerformanceDegradationReason.toString(PowerProfiles.degradationReason))
                    color: Colours.palette.m3error
                    font.pointSize: Tokens.font.size.small
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    ProfileButton {
                        Layout.fillWidth: true
                        icon: "energy_savings_leaf"
                        text: qsTr("Power Saver")
                        profile: PowerProfile.PowerSaver
                    }

                    ProfileButton {
                        Layout.fillWidth: true
                        icon: "balance"
                        text: qsTr("Balanced")
                        profile: PowerProfile.Balanced
                    }

                    ProfileButton {
                        Layout.fillWidth: true
                        icon: "rocket_launch"
                        text: qsTr("Performance")
                        profile: PowerProfile.Performance
                    }
                }
            }
        }
    }

    component ProfileButton: StyledRect {
        id: btn

        property string icon
        property string text
        property int profile
        readonly property bool active: PowerProfiles.profile === btn.profile
        readonly property color foreColour: btn.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSecondaryContainer

        implicitHeight: btnLayout.implicitHeight + Tokens.padding.normal * 2
        radius: Tokens.rounding.small
        color: btn.active ? Colours.palette.m3primary : Colours.palette.m3secondaryContainer

        StateLayer {
            color: btn.foreColour
            radius: parent.radius
            onClicked: PowerProfiles.profile = btn.profile
        }

        ColumnLayout {
            id: btnLayout

            anchors.centerIn: parent
            spacing: Tokens.spacing.smaller

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: btn.icon
                color: btn.foreColour
                font.pointSize: Tokens.font.size.large
                fill: btn.active ? 1 : 0
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
