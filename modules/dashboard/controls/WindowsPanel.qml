pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.effects
import qs.modules.popouts as BarPopouts
import qs.services
import qs.utils

Item {
    id: root

    required property var visibilities
    required property BarPopouts.Wrapper popouts

    readonly property string title: qsTr("Windows")
    readonly property real minPanelWidth: 720
    readonly property real maxListHeight: 420

    // Mirrors modules/workspacegroups/WorkspaceGroupBar.qml: workspaces are laid
    // out as ten groups of ten, so raw Hyprland ids (51) read as group 6 tab 1
    readonly property int groupSize: 10

    function groupOf(wsId: int): int {
        return Math.floor((wsId - 1) / root.groupSize) + 1;
    }

    function tabOf(wsId: int): int {
        return (wsId - 1) % root.groupSize + 1;
    }

    function labelFor(wsId: int): string {
        const label = qsTr("Group %1 · Tab %2").arg(root.groupOf(wsId)).arg(root.tabOf(wsId));
        return wsId === Hypr.activeWsId ? qsTr("%1 · current").arg(label) : label;
    }

    // Open windows bucketed by workspace, current workspace first then ascending
    readonly property var groups: {
        const byWs = new Map();
        for (const client of Hypr.toplevels?.values ?? []) {
            const ws = client.workspace;
            if (!ws)
                continue;
            if (!byWs.has(ws.id))
                byWs.set(ws.id, {
                    id: ws.id,
                    name: ws.name,
                    clients: []
                });
            byWs.get(ws.id).clients.push(client);
        }

        const activeId = Hypr.activeWsId;
        return [...byWs.values()].sort((a, b) => a.id === activeId ? -1 : b.id === activeId ? 1 : a.id - b.id);
    }

    // Same hidden-icon filtering the bar tray applies
    readonly property var trayItems: SystemTray.items.values.filter(i => !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))

    property SystemTrayItem menuItem: null

    // Hand the window off to the detached winfo popup, which owns kill/move/float
    function manage(client: var): void {
        root.popouts.winfoTarget = client;
        if (root.visibilities)
            root.visibilities.dashboard = false;
        root.popouts.detach("winfo");
    }

    function activate(item: SystemTrayItem): void {
        root.menuItem = null;
        if (root.visibilities)
            root.visibilities.dashboard = false;
        item.activate();
    }

    implicitWidth: Math.max(layout.implicitWidth, minPanelWidth)
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        spacing: Tokens.spacing.normal

        // Background apps sit above the window list: they get reached far more
        // often than any one window
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.trayItems.length > 0
            spacing: Tokens.spacing.smaller

            SectionRow {
                text: qsTr("Background apps")
            }

            Flow {
                Layout.fillWidth: true
                spacing: Tokens.spacing.normal

                Repeater {
                    model: root.trayItems

                    StyledRect {
                        id: chip

                        required property SystemTrayItem modelData

                        readonly property bool selected: root.menuItem === chip.modelData

                        implicitWidth: chipIcon.implicitWidth + Tokens.padding.large * 2
                        implicitHeight: chipIcon.implicitHeight + Tokens.padding.large * 2

                        radius: Tokens.rounding.normal
                        color: chip.selected ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

                        StateLayer {
                            radius: parent.radius

                            // Tap expands this app's options below; the same chip
                            // again collapses them, a different one switches
                            onClicked: {
                                if (chip.modelData.hasMenu)
                                    root.menuItem = chip.selected ? null : chip.modelData;
                                else
                                    root.activate(chip.modelData);
                            }
                        }

                        ColouredIcon {
                            id: chipIcon

                            anchors.centerIn: parent
                            implicitSize: Tokens.font.size.large * 1.6
                            source: Icons.getTrayIcon(chip.modelData.id, chip.modelData.icon)
                            colour: chip.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3secondary
                        }
                    }
                }
            }

            // Options for the selected app, revealed in place rather than in a popup
            WrapperItem {
                Layout.fillWidth: true
                Layout.preferredHeight: root.menuItem ? implicitHeight : 0

                clip: true
                topMargin: Tokens.spacing.smaller

                ColumnLayout {
                    spacing: Tokens.spacing.smaller

                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: openLabel.implicitHeight + Tokens.padding.normal * 2

                        radius: Tokens.rounding.normal
                        color: Colours.tPalette.m3surfaceContainer

                        StateLayer {
                            radius: parent.radius
                            onClicked: root.activate(root.menuItem)
                        }

                        StyledText {
                            id: openLabel

                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Tokens.padding.normal

                            text: qsTr("Open")
                            font.weight: 600
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        active: root.menuItem !== null

                        sourceComponent: TrayMenuList {
                            handle: root.menuItem?.menu ?? null
                            onTriggered: root.menuItem = null
                        }
                    }
                }

                Behavior on Layout.preferredHeight {
                    Anim {}
                }
            }
        }

        StyledFlickable {
            Layout.fillWidth: true
            implicitHeight: Math.min(windows.implicitHeight, root.maxListHeight)

            contentWidth: width
            contentHeight: windows.implicitHeight
            clip: true

            ColumnLayout {
                id: windows

                width: parent.width
                spacing: Tokens.spacing.normal

                Repeater {
                    model: root.groups

                    ColumnLayout {
                        id: group

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.smaller

                        SectionRow {
                            text: root.labelFor(group.modelData.id)
                            accent: group.modelData.id === Hypr.activeWsId
                        }

                        Repeater {
                            model: group.modelData.clients

                            StyledRect {
                                id: row

                                required property var modelData

                                Layout.fillWidth: true
                                implicitHeight: rowLayout.implicitHeight + Tokens.padding.normal * 2

                                radius: Tokens.rounding.normal
                                color: Colours.tPalette.m3surfaceContainer

                                StateLayer {
                                    radius: parent.radius
                                    onClicked: root.manage(row.modelData)
                                }

                                RowLayout {
                                    id: rowLayout

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: Tokens.padding.normal
                                    anchors.rightMargin: Tokens.padding.normal

                                    spacing: Tokens.spacing.normal

                                    // Window classes often have no usable
                                    // desktop-entry icon, so use the same
                                    // category glyph WorkspacePanel does
                                    MaterialIcon {
                                        Layout.alignment: Qt.AlignVCenter
                                        grade: 0
                                        text: Icons.getAppCategoryIcon(row.modelData.lastIpcObject.class ?? "", "terminal")
                                        color: Colours.palette.m3secondary
                                        font.pointSize: Tokens.font.size.extraLarge
                                    }

                                    ColumnLayout {
                                        id: rowText

                                        Layout.fillWidth: true
                                        spacing: 0

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: row.modelData.title ?? ""
                                            font.pointSize: Tokens.font.size.normal
                                            elide: Text.ElideRight
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: row.modelData.lastIpcObject.class ?? ""
                                            color: Colours.palette.m3onSurfaceVariant
                                            font.pointSize: Tokens.font.size.small
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MaterialIcon {
                                        Layout.alignment: Qt.AlignVCenter
                                        text: "chevron_right"
                                        color: Colours.palette.m3onSurfaceVariant
                                    }
                                }
                            }
                        }
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: Tokens.padding.large
                    visible: root.groups.length === 0

                    text: qsTr("No open windows")
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    component SectionRow: RowLayout {
        id: section

        property alias text: sectionLabel.text
        property bool accent

        Layout.fillWidth: true
        spacing: Tokens.spacing.normal

        StyledText {
            id: sectionLabel

            color: section.accent ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            font.pointSize: Tokens.font.size.small
            font.weight: 600
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colours.palette.m3outlineVariant
        }
    }
}
