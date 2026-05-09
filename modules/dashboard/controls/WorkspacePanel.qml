pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var visibilities

    readonly property string title: qsTr("Workspace")
    readonly property real cellWidth: 144
    readonly property real cellHeight: cellWidth * 9 / 16
    readonly property real cellSpacing: Tokens.spacing.normal

    readonly property int activeWsId: Hypr.activeWsId

    readonly property var occupied: {
        const occ = {};
        for (const ws of Hypr.workspaces.values)
            occ[ws.id] = ws.lastIpcObject.windows > 0;
        return occ;
    }

    function clientsFor(ws: int): var {
        return Hypr.toplevels.values.filter(c => c.workspace?.id === ws);
    }

    function go(ws: int): void {
        Hypr.dispatch(`workspace ${ws}`);
    }

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    GridLayout {
        id: grid

        anchors.centerIn: parent
        columns: 3
        rowSpacing: root.cellSpacing
        columnSpacing: root.cellSpacing

        Cell { ws: 7 }
        Cell { ws: 8 }
        Cell { ws: 9 }
        Cell { ws: 4 }
        Cell { ws: 5 }
        Cell { ws: 6 }
        Cell { ws: 1 }
        Cell { ws: 2 }
        Cell { ws: 3 }

        Item {
            Layout.preferredWidth: root.cellWidth
            Layout.preferredHeight: root.cellHeight
        }

        Cell { ws: 10 }

        Item {
            Layout.preferredWidth: root.cellWidth
            Layout.preferredHeight: root.cellHeight
        }
    }

    component Cell: StyledRect {
        id: cell

        required property int ws
        readonly property bool active: root.activeWsId === cell.ws
        readonly property var clients: root.clientsFor(cell.ws)

        Layout.preferredWidth: root.cellWidth
        Layout.preferredHeight: root.cellHeight

        radius: cell.active ? Tokens.rounding.normal : Tokens.rounding.small
        color: cell.active ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

        StateLayer {
            color: cell.active ? Colours.palette.m3onPrimary : Colours.palette.m3secondary
            radius: parent.radius
            onClicked: root.go(cell.ws)
        }

        Row {
            anchors.centerIn: parent
            spacing: Tokens.spacing.smaller

            Repeater {
                model: cell.clients

                MaterialIcon {
                    required property var modelData

                    grade: 0
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: cell.active ? Colours.palette.m3onPrimary : Colours.palette.m3secondary
                    font.pointSize: Tokens.font.size.large
                }
            }
        }
    }
}
