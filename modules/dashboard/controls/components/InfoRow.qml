pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

// Compact label-left / value-right row for the detail blocks inside a control
// panel. Hides itself when there is no value to show.
RowLayout {
    id: root

    property alias label: labelText.text
    property alias value: valueText.text

    Layout.fillWidth: true
    visible: valueText.text.length > 0
    spacing: Tokens.spacing.normal

    StyledText {
        id: labelText

        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Tokens.font.size.small
    }

    StyledText {
        id: valueText

        Layout.fillWidth: true
        horizontalAlignment: Text.AlignRight
        font.pointSize: Tokens.font.size.small
        elide: Text.ElideRight
    }
}
