pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Section heading for a dashboard control panel: a label, a rule filling the
// remaining width, and an optional trailing control (rescan, toggle, count).
RowLayout {
    id: root

    property alias text: label.text
    property bool accent

    default property alias trailing: trailingRow.data

    Layout.fillWidth: true
    spacing: Tokens.spacing.normal

    StyledText {
        id: label

        color: root.accent ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        font.pointSize: Tokens.font.size.small
        font.weight: 600
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Colours.palette.m3outlineVariant
    }

    RowLayout {
        id: trailingRow

        Layout.alignment: Qt.AlignVCenter
        spacing: Tokens.spacing.small
    }
}
