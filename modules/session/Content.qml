pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Column {
    id: root

    required property DrawerVisibilities visibilities

    padding: Tokens.padding.large
    spacing: Tokens.spacing.large

    SessionButton {
        id: lock

        icon: "lock"
        action: () => SessionLock.lock()

        KeyNavigation.down: hibernate

        Component.onCompleted: forceActiveFocus()

        Connections {
            function onLauncherChanged(): void {
                if (!root.visibilities.launcher)
                    lock.forceActiveFocus();
            }

            target: root.visibilities
        }
    }

    // SessionButton {
    //     id: logout
    //
    //     icon: Config.session.icons.logout
    //     command: Config.session.commands.logout
    // }

    SessionButton {
        id: hibernate

        icon: Config.session.icons.hibernate
        command: Config.session.commands.hibernate

        KeyNavigation.up: lock
        KeyNavigation.down: reboot
    }

    SessionButton {
        id: reboot

        icon: Config.session.icons.reboot
        command: Config.session.commands.reboot

        KeyNavigation.up: hibernate
        KeyNavigation.down: shutdown
    }

    SessionButton {
        id: shutdown

        icon: Config.session.icons.shutdown
        command: Config.session.commands.shutdown

        KeyNavigation.up: reboot
    }

    component SessionButton: StyledRect {
        id: button

        required property string icon
        property list<string> command
        property var action: () => Quickshell.execDetached(button.command)

        implicitWidth: Tokens.sizes.session.button
        implicitHeight: Tokens.sizes.session.button

        radius: Tokens.rounding.large
        color: button.activeFocus ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

        Keys.onEnterPressed: button.action()
        Keys.onReturnPressed: button.action()
        Keys.onEscapePressed: root.visibilities.session = false
        Keys.onPressed: event => {
            if (!Config.session.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if ((event.key === Qt.Key_J || event.key === Qt.Key_N) && KeyNavigation.down) {
                    KeyNavigation.down.focus = true;
                    event.accepted = true;
                } else if ((event.key === Qt.Key_K || event.key === Qt.Key_P) && KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab && KeyNavigation.down) {
                KeyNavigation.down.focus = true;
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                if (KeyNavigation.up) {
                    KeyNavigation.up.focus = true;
                    event.accepted = true;
                }
            }
        }

        StateLayer {
            radius: parent.radius
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            onClicked: button.action()
        }

        MaterialIcon {
            anchors.centerIn: parent

            text: button.icon
            color: button.activeFocus ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            font.pointSize: Tokens.font.size.extraLarge
            font.weight: 500
        }
    }
}
