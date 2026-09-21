pragma ComponentBehavior: Bound

import "components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    readonly property string title: qsTr("Ethernet")
    readonly property real minPanelWidth: 720
    readonly property real maxListHeight: 420

    // Row currently showing its actions, keyed by interface; "" for none
    property string expandedInterface: ""

    // Link speed and duplex, which nmcli does not report for wired devices
    property var linkInfo: null

    readonly property var devices: [...Nmcli.ethernetDevices].sort((a, b) => (b.connected - a.connected) || (a.interface || "").localeCompare(b.interface || ""))
    readonly property var active: Nmcli.activeEthernet

    function describe(device: var): string {
        if (!device)
            return "";
        if (device.connected)
            return device.connection || qsTr("Connected");
        if (device.state === "unavailable")
            return qsTr("Cable unplugged");
        return device.connection || qsTr("Disconnected");
    }

    function parseLink(text: string): var {
        const lines = text.trim().split("\n");
        const speed = parseInt(lines[0] ?? "", 10);
        const duplex = (lines[1] ?? "").trim();

        return {
            // sysfs reports -1 when the link is down
            speed: speed > 0 ? qsTr("%1 Mb/s").arg(speed) : "",
            duplex: duplex && duplex !== "unknown" ? duplex : ""
        };
    }

    function refreshDetails(device: var): void {
        root.linkInfo = null;

        const iface = device?.interface ?? "";
        if (!iface)
            return;

        Nmcli.getEthernetDeviceDetails(iface, () => {});

        // Speed and duplex only exist in sysfs; argv form, no shell involved
        const base = "/sys/class/net/" + iface + "/";
        linkProc.exec(["cat", base + "speed", base + "duplex"]);
    }

    function toggleRow(device: var): void {
        const name = device?.interface ?? "";
        root.expandedInterface = root.expandedInterface === name ? "" : name;

        if (root.expandedInterface)
            root.refreshDetails(device);
    }

    function toggleConnection(device: var): void {
        root.expandedInterface = "";
        if (device.connected && device.connection)
            Nmcli.disconnectEthernet(device.connection, () => {});
        else
            Nmcli.connectEthernet(device.connection || "", device.interface || "", () => {});
    }

    implicitWidth: Math.max(layout.implicitWidth, minPanelWidth)
    implicitHeight: layout.implicitHeight

    // Nothing else refreshes the wired device list once the shell has started
    Component.onCompleted: Nmcli.getEthernetInterfaces(() => {})

    Process {
        id: linkProc

        stdout: StdioCollector {
            onStreamFinished: root.linkInfo = root.parseLink(text)
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        spacing: Tokens.spacing.normal

        // Summary, with the same icon the bar status uses. Wired has no radio to
        // switch, so this is status only rather than a toggle.
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: summaryRow.implicitHeight + Tokens.padding.normal * 2

            radius: Tokens.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: summaryRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.normal
                anchors.rightMargin: Tokens.padding.normal

                spacing: Tokens.spacing.normal

                MaterialIcon {
                    text: "cable"
                    color: root.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.active ? (root.active.connection || root.active.interface) : qsTr("Not connected")
                    font.pointSize: Tokens.font.size.normal
                    elide: Text.ElideRight
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.large
            visible: root.devices.length === 0

            text: qsTr("No wired adapters found")
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
        }

        StyledFlickable {
            Layout.fillWidth: true
            visible: root.devices.length > 0
            implicitHeight: visible ? Math.min(lists.implicitHeight, root.maxListHeight) : 0

            contentWidth: width
            contentHeight: lists.implicitHeight
            clip: true

            ColumnLayout {
                id: lists

                width: parent.width
                spacing: Tokens.spacing.small / 2

                PanelSection {
                    text: qsTr("Adapters")
                }

                Repeater {
                    model: root.devices

                    ExpandableRow {
                        id: deviceRow

                        required property var modelData

                        icon: "cable"
                        title: deviceRow.modelData.interface || qsTr("Unknown")
                        subtitle: root.describe(deviceRow.modelData)
                        accent: deviceRow.modelData.connected
                        expanded: root.expandedInterface === (deviceRow.modelData.interface ?? "")

                        onClicked: root.toggleRow(deviceRow.modelData)

                        TextButton {
                            Layout.fillWidth: true
                            text: deviceRow.modelData.connected ? qsTr("Disconnect") : qsTr("Connect")
                            inactiveColour: deviceRow.modelData.connected ? Colours.palette.m3secondaryContainer : Colours.palette.m3primary
                            inactiveOnColour: deviceRow.modelData.connected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onPrimary
                            onClicked: root.toggleConnection(deviceRow.modelData)
                        }

                        StyledRect {
                            Layout.fillWidth: true
                            Layout.topMargin: Tokens.spacing.small / 2
                            visible: deviceRow.modelData.connected
                            implicitHeight: details.implicitHeight + Tokens.padding.normal * 2

                            radius: Tokens.rounding.normal
                            color: Colours.tPalette.m3surfaceContainer

                            ColumnLayout {
                                id: details

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Tokens.padding.normal
                                anchors.rightMargin: Tokens.padding.normal

                                spacing: Tokens.spacing.small / 2

                                InfoRow {
                                    label: qsTr("IP address")
                                    value: Nmcli.ethernetDeviceDetails?.ipAddress ?? ""
                                }

                                InfoRow {
                                    label: qsTr("Subnet mask")
                                    value: Nmcli.ethernetDeviceDetails?.subnet ?? ""
                                }

                                InfoRow {
                                    label: qsTr("Gateway")
                                    value: Nmcli.ethernetDeviceDetails?.gateway ?? ""
                                }

                                InfoRow {
                                    label: qsTr("DNS")
                                    value: (Nmcli.ethernetDeviceDetails?.dns ?? []).join(", ")
                                }

                                InfoRow {
                                    label: qsTr("Link speed")
                                    value: {
                                        const speed = root.linkInfo?.speed ?? "";
                                        const duplex = root.linkInfo?.duplex ?? "";
                                        if (!speed)
                                            return "";
                                        return duplex ? qsTr("%1 · %2 duplex").arg(speed).arg(duplex) : speed;
                                    }
                                }

                                InfoRow {
                                    label: qsTr("MAC address")
                                    value: Nmcli.ethernetDeviceDetails?.macAddress ?? ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
