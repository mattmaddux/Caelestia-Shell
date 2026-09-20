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

    readonly property string title: qsTr("Wi-Fi")
    readonly property real minPanelWidth: 720
    readonly property real maxListHeight: 420

    // Row currently showing its actions, keyed by ssid; "" for none
    property string expandedSsid: ""
    property string connectingSsid: ""
    property string passwordSsid: ""

    readonly property var connected: Nmcli.active

    // Live link stats from `iw`, which reports the negotiated rate and channel
    // width that nmcli does not expose. Absent iw, those rows simply hide.
    property var linkInfo: null

    function channelFor(freq: int): int {
        if (freq === 2484)
            return 14;
        if (freq >= 2412 && freq <= 2472)
            return (freq - 2407) / 5;
        if (freq >= 5955)
            return (freq - 5950) / 5;
        if (freq >= 5000)
            return (freq - 5000) / 5;
        return 0;
    }

    function bandFor(freq: int): string {
        if (freq >= 5955)
            return qsTr("6 GHz");
        if (freq >= 5000)
            return qsTr("5 GHz");
        if (freq > 0)
            return qsTr("2.4 GHz");
        return "";
    }

    function parseLink(text: string): var {
        const info = {
            signal: "",
            rate: "",
            width: ""
        };

        for (const raw of text.split("\n")) {
            const line = raw.trim();
            if (line.startsWith("signal:")) {
                info.signal = line.slice("signal:".length).trim();
            } else if (line.startsWith("tx bitrate:")) {
                const rest = line.slice("tx bitrate:".length).trim();
                const match = rest.match(/^([\d.]+\s*\S+)(?:\s+(\d+MHz))?/);
                if (match) {
                    info.rate = match[1];
                    info.width = (match[2] ?? "").replace("MHz", " MHz");
                }
            }
        }

        return info;
    }

    // Resolved on demand rather than from startup state, which is not always
    // populated by the time the panel opens
    function refreshDetails(): void {
        root.linkInfo = null;
        Nmcli.getWirelessInterfaces(interfaces => {
            const active = interfaces.find(i => Nmcli.isConnectedState(i.state));
            const device = active?.device ?? "";
            if (!device)
                return;

            Nmcli.getWirelessDeviceDetails(device, () => {});
            linkProc.exec(["iw", "dev", device, "link"]);
        });
    }

    function byStrength(a: var, b: var): int {
        return b.strength - a.strength;
    }

    // Nmcli already tracks which ssids have a saved profile, so the saved and
    // available splits come straight off that
    readonly property var saved: Nmcli.networks.filter(n => !n.active && Nmcli.savedConnectionSsids.includes(n.ssid)).sort(root.byStrength)
    readonly property var available: Nmcli.networks.filter(n => !n.active && !Nmcli.savedConnectionSsids.includes(n.ssid)).sort(root.byStrength)

    function describe(network: var): string {
        if (!network)
            return "";

        let quality;
        if (network.strength >= 80)
            quality = qsTr("Excellent");
        else if (network.strength >= 60)
            quality = qsTr("Good");
        else if (network.strength >= 40)
            quality = qsTr("Fair");
        else
            quality = qsTr("Weak");

        return `${quality} · ${network.isSecure ? network.security : qsTr("Open")}`;
    }

    function toggleRow(ssid: string): void {
        root.expandedSsid = root.expandedSsid === ssid ? "" : ssid;
        root.passwordSsid = "";

        if (root.expandedSsid && root.expandedSsid === root.connected?.ssid)
            root.refreshDetails();
    }

    Process {
        id: linkProc

        stdout: StdioCollector {
            onStreamFinished: root.linkInfo = root.parseLink(text)
        }
    }

    function connect(network: var): void {
        root.connectingSsid = network.ssid;
        NetworkConnection.handleConnect(network, null, n => {
            // Secure network with no saved profile; ask for the key in place
            root.connectingSsid = "";
            root.passwordSsid = n.ssid;
            root.expandedSsid = n.ssid;
        });
    }

    function connectWithPassword(network: var, password: string): void {
        root.connectingSsid = network.ssid;
        root.passwordSsid = "";
        NetworkConnection.connectWithPassword(network, password, () => {
            root.connectingSsid = "";
        });
    }

    function forget(ssid: string): void {
        root.expandedSsid = "";
        Nmcli.forgetNetwork(ssid, () => {});
    }

    implicitWidth: Math.max(layout.implicitWidth, minPanelWidth)
    implicitHeight: layout.implicitHeight

    // Nothing else refreshes Nmcli once it has started, so pull the current AP
    // list and saved profiles when the panel opens rather than showing whatever
    // the service happened to cache at shell start. A full rescan stays on the
    // explicit button since it drives a hardware scan.
    Component.onCompleted: {
        if (Nmcli.wifiEnabled) {
            Nmcli.getNetworks(() => {});
            Nmcli.loadSavedConnections(() => {});
        }
    }

    Connections {
        function onActiveChanged(): void {
            if (Nmcli.active && Nmcli.active.ssid === root.connectingSsid)
                root.connectingSsid = "";
        }

        function onConnectionFailed(ssid: string): void {
            if (root.connectingSsid === ssid)
                root.connectingSsid = "";
        }

        target: Nmcli
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        spacing: Tokens.spacing.normal

        // Radio toggle, with the same icon the bar status uses
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
                    text: Nmcli.wifiEnabled ? Icons.getNetworkIcon(Nmcli.active?.strength ?? 0) : "wifi_off"
                    color: Nmcli.wifiEnabled && Nmcli.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.large
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Nmcli.active ? Nmcli.active.ssid : Nmcli.wifiEnabled ? qsTr("Not connected") : qsTr("Off")
                    font.pointSize: Tokens.font.size.normal
                }

                StyledSwitch {
                    checked: Nmcli.wifiEnabled
                    onToggled: Nmcli.enableWifi(checked, () => Nmcli.getNetworks(() => {}))
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.large
            visible: !Nmcli.wifiEnabled

            text: qsTr("Wi-Fi is off")
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
        }

        StyledFlickable {
            Layout.fillWidth: true
            visible: Nmcli.wifiEnabled
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
                    visible: !!root.connected
                    spacing: Tokens.spacing.small / 2

                    PanelSection {
                        text: qsTr("Connected")
                        accent: true
                    }

                    NetworkRow {
                        id: connectedRow

                        network: root.connected
                        accent: true

                        TextButton {
                            Layout.fillWidth: true
                            text: qsTr("Disconnect")
                            inactiveColour: Colours.palette.m3secondaryContainer
                            inactiveOnColour: Colours.palette.m3onSecondaryContainer
                            onClicked: {
                                root.expandedSsid = "";
                                Nmcli.disconnectFromNetwork();
                            }
                        }

                        TextButton {
                            Layout.fillWidth: true
                            text: qsTr("Forget")
                            inactiveColour: Colours.palette.m3errorContainer
                            inactiveOnColour: Colours.palette.m3onErrorContainer
                            onClicked: root.forget(connectedRow.network?.ssid ?? "")
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
                                    label: qsTr("IP address")
                                    value: Nmcli.wirelessDeviceDetails?.ipAddress ?? ""
                                }

                                InfoRow {
                                    label: qsTr("Subnet mask")
                                    value: Nmcli.wirelessDeviceDetails?.subnet ?? ""
                                }

                                InfoRow {
                                    label: qsTr("Gateway")
                                    value: Nmcli.wirelessDeviceDetails?.gateway ?? ""
                                }

                                InfoRow {
                                    label: qsTr("DNS")
                                    value: (Nmcli.wirelessDeviceDetails?.dns ?? []).join(", ")
                                }

                                InfoRow {
                                    label: qsTr("Signal")
                                    value: {
                                        const strength = connectedRow.network?.strength ?? 0;
                                        const dbm = root.linkInfo?.signal ?? "";
                                        return dbm ? qsTr("%1% · %2").arg(strength).arg(dbm) : qsTr("%1%").arg(strength);
                                    }
                                }

                                InfoRow {
                                    label: qsTr("Channel")
                                    value: {
                                        const freq = connectedRow.network?.frequency ?? 0;
                                        const channel = root.channelFor(freq);
                                        if (!channel)
                                            return "";
                                        const width = root.linkInfo?.width ?? "";
                                        const base = qsTr("%1 · %2").arg(channel).arg(root.bandFor(freq));
                                        return width ? `${base} · ${width}` : base;
                                    }
                                }

                                InfoRow {
                                    label: qsTr("Link speed")
                                    value: root.linkInfo?.rate ?? ""
                                }

                                InfoRow {
                                    label: qsTr("Security")
                                    value: connectedRow.network?.security ?? ""
                                }

                                InfoRow {
                                    label: qsTr("MAC address")
                                    value: Nmcli.wirelessDeviceDetails?.macAddress ?? ""
                                }
                            }
                        }
                    }
                }

                // Saved but not connected
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.saved.length > 0
                    spacing: Tokens.spacing.small / 2

                    PanelSection {
                        text: qsTr("Saved")
                    }

                    Repeater {
                        model: root.saved

                        NetworkRow {
                            id: savedRow

                            required property var modelData

                            network: savedRow.modelData

                            TextButton {
                                Layout.fillWidth: true
                                text: qsTr("Connect")
                                onClicked: root.connect(savedRow.network)
                            }

                            TextButton {
                                Layout.fillWidth: true
                                text: qsTr("Forget")
                                inactiveColour: Colours.palette.m3errorContainer
                                inactiveOnColour: Colours.palette.m3onErrorContainer
                                onClicked: root.forget(savedRow.network.ssid)
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
                            text: Nmcli.scanning ? qsTr("Scanning…") : qsTr("Rescan")
                            font.pointSize: Tokens.font.size.small
                            verticalPadding: Tokens.padding.smaller / 2
                            onClicked: Nmcli.rescanWifi()
                        }
                    }

                    Repeater {
                        model: root.available

                        NetworkRow {
                            id: availableRow

                            required property var modelData

                            network: availableRow.modelData

                            // Secure networks with no profile ask for the key in
                            // place rather than opening a separate dialog
                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: root.passwordSsid === availableRow.network.ssid
                                spacing: Tokens.spacing.small / 2

                                StyledRect {
                                    Layout.fillWidth: true
                                    implicitHeight: passwordField.implicitHeight + Tokens.padding.normal * 2

                                    radius: Tokens.rounding.normal
                                    color: Colours.palette.m3surfaceContainerHighest

                                    StyledTextField {
                                        id: passwordField

                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: Tokens.padding.normal
                                        anchors.rightMargin: Tokens.padding.normal

                                        echoMode: TextInput.Password
                                        placeholderText: qsTr("Password")
                                        onAccepted: root.connectWithPassword(availableRow.network, text)
                                    }
                                }

                                TextButton {
                                    Layout.fillWidth: true
                                    text: qsTr("Connect")
                                    onClicked: root.connectWithPassword(availableRow.network, passwordField.text)
                                }
                            }

                            TextButton {
                                Layout.fillWidth: true
                                visible: root.passwordSsid !== availableRow.network.ssid
                                text: qsTr("Connect")
                                onClicked: root.connect(availableRow.network)
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.padding.large
                    visible: Nmcli.networks.length === 0

                    text: Nmcli.scanning ? qsTr("Scanning for networks…") : qsTr("No networks found")
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    component NetworkRow: ExpandableRow {
        id: netRow

        required property var network

        icon: Icons.getNetworkIcon(netRow.network?.strength ?? 0, netRow.network?.isSecure ?? false)
        title: netRow.network?.ssid ?? ""
        subtitle: root.describe(netRow.network)
        expanded: root.expandedSsid === (netRow.network?.ssid ?? "")
        busy: root.connectingSsid === (netRow.network?.ssid ?? "")

        onClicked: root.toggleRow(netRow.network?.ssid ?? "")
    }
}
