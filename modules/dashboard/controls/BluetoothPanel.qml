pragma ComponentBehavior: Bound

import "components"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    readonly property string title: qsTr("Bluetooth")
    readonly property real minPanelWidth: 720
    readonly property real maxListHeight: 420

    // Row currently showing its actions, keyed by address; "" for none
    property string expandedAddress: ""

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: root.adapter?.enabled ?? false

    readonly property var devices: Bluetooth.devices?.values ?? []

    function byName(a: var, b: var): int {
        return a.name.localeCompare(b.name);
    }

    // bonded distinguishes "we have a pairing" from "merely in range"
    readonly property var connectedDevices: root.devices.filter(d => d.connected).sort(root.byName)
    readonly property var pairedDevices: root.devices.filter(d => d.bonded && !d.connected).sort(root.byName)
    readonly property var availableDevices: root.devices.filter(d => !d.bonded && !d.connected).sort(root.byName)

    function isBusy(device: var): bool {
        return device?.state === BluetoothDeviceState.Connecting || device?.state === BluetoothDeviceState.Disconnecting;
    }

    function batteryText(device: var): string {
        if (!device?.batteryAvailable)
            return "";
        return qsTr("%1%").arg(Math.round(device.battery * 100));
    }

    function describe(device: var): string {
        if (!device)
            return "";

        const parts = [];
        if (device.connected)
            parts.push(qsTr("Connected"));
        else if (device.bonded)
            parts.push(qsTr("Paired"));
        else
            parts.push(device.address);

        const battery = root.batteryText(device);
        if (battery)
            parts.push(battery);

        return parts.join(" · ");
    }

    function toggleRow(address: string): void {
        root.expandedAddress = root.expandedAddress === address ? "" : address;
    }

    implicitWidth: Math.max(layout.implicitWidth, minPanelWidth)
    implicitHeight: layout.implicitHeight

    // Leaving the adapter scanning after the panel closes would keep the radio
    // busy for no one's benefit
    Component.onDestruction: {
        if (root.adapter?.discovering)
            root.adapter.discovering = false;
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        spacing: Tokens.spacing.normal

        // Adapter toggle, with the same icon the bar status uses
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: toggleRow.implicitHeight + Tokens.padding.normal * 2

            radius: Tokens.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            RowLayout {
                id: toggleRow

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Tokens.padding.normal
                anchors.rightMargin: Tokens.padding.normal

                spacing: Tokens.spacing.normal

                MaterialIcon {
                    text: {
                        if (!root.enabled)
                            return "bluetooth_disabled";
                        if (root.connectedDevices.length > 0)
                            return "bluetooth_connected";
                        return "bluetooth";
                    }
                    color: root.enabled && root.connectedDevices.length > 0 ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        if (!root.enabled)
                            return qsTr("Off");
                        const count = root.connectedDevices.length;
                        if (count === 0)
                            return qsTr("No devices connected");
                        if (count === 1)
                            return root.connectedDevices[0].name;
                        return qsTr("%1 devices connected").arg(count);
                    }
                    font.pointSize: Tokens.font.size.normal
                    elide: Text.ElideRight
                }

                StyledSwitch {
                    checked: root.enabled
                    onToggled: {
                        if (root.adapter)
                            root.adapter.enabled = checked;
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.large
            visible: !root.enabled

            text: qsTr("Bluetooth is off")
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
        }

        StyledFlickable {
            Layout.fillWidth: true
            visible: root.enabled
            implicitHeight: visible ? Math.min(lists.implicitHeight, root.maxListHeight) : 0

            contentWidth: width
            contentHeight: lists.implicitHeight
            clip: true

            ColumnLayout {
                id: lists

                width: parent.width
                spacing: Tokens.spacing.normal

                // Connected
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.connectedDevices.length > 0
                    spacing: Tokens.spacing.small / 2

                    PanelSection {
                        text: qsTr("Connected")
                        accent: true
                    }

                    Repeater {
                        model: root.connectedDevices

                        DeviceRow {
                            id: connectedRow

                            required property var modelData

                            device: connectedRow.modelData
                            accent: true

                            TextButton {
                                Layout.fillWidth: true
                                text: qsTr("Disconnect")
                                inactiveColour: Colours.palette.m3secondaryContainer
                                inactiveOnColour: Colours.palette.m3onSecondaryContainer
                                onClicked: connectedRow.device.connected = false
                            }

                            TextButton {
                                Layout.fillWidth: true
                                text: qsTr("Forget")
                                inactiveColour: Colours.palette.m3errorContainer
                                inactiveOnColour: Colours.palette.m3onErrorContainer
                                onClicked: {
                                    root.expandedAddress = "";
                                    connectedRow.device.forget();
                                }
                            }

                            StyledRect {
                                Layout.fillWidth: true
                                Layout.topMargin: Tokens.spacing.small / 2
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
                                        label: qsTr("Address")
                                        value: connectedRow.device?.address ?? ""
                                    }

                                    InfoRow {
                                        label: qsTr("Battery")
                                        value: root.batteryText(connectedRow.device)
                                    }

                                    InfoRow {
                                        label: qsTr("Paired")
                                        value: connectedRow.device?.paired ? qsTr("Yes") : qsTr("No")
                                    }

                                    InfoRow {
                                        label: qsTr("Trusted")
                                        value: connectedRow.device?.trusted ? qsTr("Yes") : qsTr("No")
                                    }
                                }
                            }
                        }
                    }
                }

                // Paired but not connected
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.pairedDevices.length > 0
                    spacing: Tokens.spacing.small / 2

                    PanelSection {
                        text: qsTr("Paired")
                    }

                    Repeater {
                        model: root.pairedDevices

                        DeviceRow {
                            id: pairedRow

                            required property var modelData

                            device: pairedRow.modelData

                            TextButton {
                                Layout.fillWidth: true
                                text: qsTr("Connect")
                                onClicked: pairedRow.device.connected = true
                            }

                            TextButton {
                                Layout.fillWidth: true
                                text: qsTr("Forget")
                                inactiveColour: Colours.palette.m3errorContainer
                                inactiveOnColour: Colours.palette.m3onErrorContainer
                                onClicked: {
                                    root.expandedAddress = "";
                                    pairedRow.device.forget();
                                }
                            }
                        }
                    }
                }

                // Everything else in range
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small / 2

                    PanelSection {
                        text: qsTr("Available")

                        TextButton {
                            type: TextButton.Text
                            text: root.adapter?.discovering ? qsTr("Stop scan") : qsTr("Scan")
                            font.pointSize: Tokens.font.size.small
                            verticalPadding: Tokens.padding.smaller / 2
                            onClicked: {
                                if (root.adapter)
                                    root.adapter.discovering = !root.adapter.discovering;
                            }
                        }
                    }

                    Repeater {
                        model: root.availableDevices

                        DeviceRow {
                            id: availableRow

                            required property var modelData

                            device: availableRow.modelData

                            TextButton {
                                Layout.fillWidth: true
                                text: qsTr("Pair")
                                onClicked: availableRow.device.pair()
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.padding.normal
                        visible: root.availableDevices.length === 0

                        text: root.adapter?.discovering ? qsTr("Scanning for devices…") : qsTr("Scan to discover nearby devices")
                        color: Colours.palette.m3onSurfaceVariant
                        horizontalAlignment: Text.AlignHCenter
                        font.pointSize: Tokens.font.size.small
                    }
                }
            }
        }
    }

    component DeviceRow: ExpandableRow {
        id: devRow

        required property var device

        icon: Icons.getBluetoothIcon(devRow.device?.icon ?? "")
        title: devRow.device?.name ?? ""
        subtitle: root.describe(devRow.device)
        expanded: root.expandedAddress === (devRow.device?.address ?? "")
        busy: root.isBusy(devRow.device)

        onClicked: root.toggleRow(devRow.device?.address ?? "")
    }
}
