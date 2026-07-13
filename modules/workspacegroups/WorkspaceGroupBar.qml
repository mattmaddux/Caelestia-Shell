pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

// Single-line workspace picker for the top bar. The ten groups (projects) sit in
// a row; a single themed pill (m3primary) slides between them to mark the active
// group — and, when that group has more than one tab, the pill widens in place to
// hold the tabs (occupied ones, plus the active tab if empty), pushing neighbours
// apart. Row height is constant, so nothing below the bar moves. Numbers and tabs
// are clickable (group → its tab 1; tab → that workspace).
// (The active group's own number is hidden while expanded; TODO: surface it.)
Item {
    id: root

    readonly property int groupSize: 10
    readonly property int activeGroup: Math.floor((Hypr.activeWsId - 1) / groupSize)
    readonly property int base: activeGroup * groupSize

    readonly property var occupied: {
        const occ = {};
        for (const ws of Hypr.workspaces.values)
            occ[ws.id] = ws.lastIpcObject.windows > 0;
        return occ;
    }

    readonly property var tabList: {
        const list = [];
        for (let i = 0; i < root.groupSize; i++) {
            const id = root.base + i + 1;
            if ((root.occupied[id] ?? false) || Hypr.activeWsId === id)
                list.push({
                    index: i,
                    wsId: id,
                    active: Hypr.activeWsId === id
                });
        }
        return list;
    }

    // The active group's slot delegate, so the pill can track its geometry.
    readonly property Item activeItem: groupRepeater.count > 0 ? groupRepeater.itemAt(activeGroup) : null

    // Constant row height, driven by the group-number font.
    // Pill hugs the number (thin); the picker is a bit taller so the pill has
    // vertical breathing room above and below within the bar. Height is derived
    // from FontMetrics (stable) rather than an invisible Text, whose
    // implicitHeight can collapse to 0 during font/appearance re-evaluation and
    // stick there, shrinking the whole top bar.
    readonly property real pillHeight: metric.height + Tokens.padding.small * 2

    implicitWidth: row.implicitWidth + Tokens.padding.normal * 2
    implicitHeight: pillHeight + Tokens.padding.small * 2

    FontMetrics {
        id: metric

        font.family: Tokens.font.family.sans
        font.pointSize: Tokens.font.size.smaller
    }

    // Subtle container behind the picker, matching the left-bar status/workspace
    // pills (surface container, fully rounded).
    StyledRect {
        anchors.fill: parent

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.full
    }

    // Single selection pill that slides/resizes to the active group.
    StyledRect {
        id: pill

        x: row.x + (root.activeItem?.x ?? 0)
        y: row.y
        implicitWidth: root.activeItem?.width ?? 0
        implicitHeight: root.pillHeight
        radius: Tokens.rounding.full
        color: Colours.palette.m3primary

        Behavior on x {
            Anim {
                type: Anim.Emphasized
            }
        }
        Behavior on implicitWidth {
            Anim {
                type: Anim.Emphasized
            }
        }
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        Repeater {
            id: groupRepeater

            model: root.groupSize

            Item {
                id: slot

                required property int index

                readonly property bool active: root.activeGroup === index
                readonly property bool expanded: active && root.tabList.length > 1
                property bool hovered

                implicitWidth: (expanded ? tabRow.implicitWidth : label.implicitWidth) + Tokens.padding.normal * 2
                implicitHeight: root.pillHeight

                // Declared before the label so the label's hover-colour binding can
                // reference slotMouse (forward id refs fail under ComponentBehavior:
                // Bound). It sits behind the label/tabs, which are input-transparent.
                MouseArea {
                    id: slotMouse

                    anchors.fill: parent
                    enabled: !slot.expanded
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: slot.hovered = containsMouse
                    onClicked: Hypr.dispatch(`workspace ${slot.index * root.groupSize + 1}`)
                }

                StyledText {
                    id: label

                    anchors.centerIn: parent
                    visible: !slot.expanded

                    text: ((slot.index + 1) % 10).toString()
                    font.pointSize: Tokens.font.size.smaller
                    color: slot.active ? Colours.palette.m3onPrimary : slot.hovered ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                }

                Row {
                    id: tabRow

                    anchors.centerIn: parent
                    visible: slot.expanded
                    spacing: Tokens.spacing.normal

                    Repeater {
                        model: ScriptModel {
                            values: slot.expanded ? root.tabList : []
                        }

                        StyledText {
                            required property var modelData

                            text: ((modelData.index + 1) % 10).toString()
                            font.pointSize: Tokens.font.size.small
                            color: modelData.active ? Colours.palette.m3onPrimary : Qt.alpha(Colours.palette.m3onPrimary, 0.6)

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -Tokens.spacing.normal / 2
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hypr.dispatch(`workspace ${modelData.wsId}`)
                            }
                        }
                    }
                }
            }
        }
    }
}
