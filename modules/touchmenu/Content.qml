pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var target
    required property ShellScreen screen
    signal close

    property int mode: 0  // 0 = main grid, 1 = workspace picker, 2 = swap select banner

    property real buttonSize: 80

    readonly property real contentWidth: {
        if (mode === 0)
            return buttonSize * 2 + Tokens.spacing.normal;
        if (mode === 1)
            return buttonSize * 3 + Tokens.spacing.normal * 2;
        return banner.implicitWidth;
    }

    readonly property real contentHeight: {
        if (mode === 0)
            return buttonSize * 2 + Tokens.spacing.normal;
        if (mode === 1)
            return buttonSize * 4 + Tokens.spacing.normal * 3;
        return banner.implicitHeight;
    }

    width: contentWidth + Tokens.padding.large * 2
    height: contentHeight + Tokens.padding.large * 2

    StyledRect {
        anchors.fill: parent
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large
    }

    StackLayout {
        id: stack

        x: Tokens.padding.large
        y: Tokens.padding.large
        currentIndex: root.mode

        // Mode 0: 2x2 main grid
        GridLayout {
            columns: 2
            rowSpacing: Tokens.spacing.normal
            columnSpacing: Tokens.spacing.normal

            ActionButton {
                icon: "close"
                onClicked: {
                    if (root.target)
                        Hypr.dispatch(`closewindow address:0x${root.target.address}`);
                    root.close();
                }
            }

            ActionButton {
                icon: "select_window_2"
                onClicked: root.mode = 1
            }

            ActionButton {
                icon: "swap_horiz"
                onClicked: root.mode = 2
            }

            ActionButton {
                icon: "info"
                onClicked: {
                    WindowInfoBus.openRequested(root.screen);
                    root.close();
                }
            }
        }

        // Mode 1: workspace picker (3x3 + 0 below)
        ColumnLayout {
            spacing: Tokens.spacing.normal

            GridLayout {
                Layout.alignment: Qt.AlignHCenter
                columns: 3
                rowSpacing: Tokens.spacing.normal
                columnSpacing: Tokens.spacing.normal

                Repeater {
                    model: [7, 8, 9, 4, 5, 6, 1, 2, 3]

                    ActionButton {
                        required property int modelData

                        label: modelData.toString()
                        onClicked: {
                            if (root.target)
                                Hypr.dispatch(`movetoworkspace ${modelData},address:0x${root.target.address}`);
                            root.close();
                        }
                    }
                }
            }

            ActionButton {
                Layout.alignment: Qt.AlignHCenter
                label: "0"
                onClicked: {
                    if (root.target)
                        Hypr.dispatch(`movetoworkspace 10,address:0x${root.target.address}`);
                    root.close();
                }
            }
        }

        // Mode 2: swap-select banner
        StyledText {
            id: banner

            text: "Tap a window to swap"
            color: Colours.palette.m3onSurface
            font.pointSize: Tokens.font.size.large
            font.weight: 500
        }
    }

    component ActionButton: StyledRect {
        id: button

        property string icon
        property string label
        signal clicked

        Layout.preferredWidth: root.buttonSize
        Layout.preferredHeight: root.buttonSize
        implicitWidth: root.buttonSize
        implicitHeight: root.buttonSize

        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainerHigh

        StateLayer {
            radius: parent.radius
            onClicked: button.clicked()
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: button.icon
            text: button.icon
            color: Colours.palette.m3onSurface
            font.pointSize: Tokens.font.size.extraLarge
            font.weight: 500
        }

        StyledText {
            anchors.centerIn: parent
            visible: button.label
            text: button.label
            color: Colours.palette.m3onSurface
            font.pointSize: Tokens.font.size.extraLarge
            font.weight: 500
        }
    }
}
