pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

GridLayout {
    id: root

    required property Pam pam
    property real buttonSize: 64

    columns: 3
    rowSpacing: Tokens.spacing.normal
    columnSpacing: Tokens.spacing.normal

    Repeater {
        model: ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

        KeypadButton {
            required property string modelData

            label: modelData
            onClicked: {
                if (root.pam.passwd.active || root.pam.state === "max")
                    return;
                root.pam.buffer += modelData;
            }
        }
    }

    Item {
        Layout.preferredWidth: root.buttonSize
        Layout.preferredHeight: root.buttonSize
    }

    KeypadButton {
        label: "0"
        onClicked: {
            if (root.pam.passwd.active || root.pam.state === "max")
                return;
            root.pam.buffer += "0";
        }
    }

    Item {
        Layout.preferredWidth: root.buttonSize
        Layout.preferredHeight: root.buttonSize
    }

    component KeypadButton: StyledRect {
        id: button

        property string label
        property string icon
        property bool primary

        signal clicked

        Layout.preferredWidth: root.buttonSize
        Layout.preferredHeight: root.buttonSize

        radius: Tokens.rounding.full
        color: primary ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainer

        StateLayer {
            radius: parent.radius
            color: button.primary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            onClicked: button.clicked()
        }

        StyledText {
            anchors.centerIn: parent
            visible: button.label
            text: button.label
            color: button.primary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            font.pointSize: Tokens.font.size.extraLarge
            font.weight: 500
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: button.icon
            text: button.icon
            color: button.primary ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            font.pointSize: Tokens.font.size.extraLarge
            font.weight: 500
        }
    }
}
