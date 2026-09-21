import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.dashboard as Dashboard
import qs.modules.launcher as Launcher
import qs.modules.notifications as Notifications
import qs.modules.osd as Osd
import qs.modules.sidebar as Sidebar
import qs.modules.popouts as BarPopouts
import qs.modules.utilities.toasts as Toasts

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property real borderThickness
    required property real topBarThickness
    // Height the dashboard's tab strip currently occupies in the top bar
    required property real dashTabsHeight

    readonly property alias osd: osd
    readonly property alias osdWrapper: osdWrapper
    readonly property alias notifications: notifications
    readonly property alias launcher: launcher
    readonly property alias dashboard: dashboard
    readonly property alias popouts: popoutsWrapper.content
    readonly property alias popoutsWrapper: popoutsWrapper
    readonly property alias toasts: toasts
    readonly property alias sidebar: sidebar

    anchors.fill: parent
    anchors.margins: borderThickness
    // Top edge is the thick top bar, not the thin border, so panels (esp. the
    // top-anchored dashboard) sit below the top bar instead of behind it.
    anchors.topMargin: topBarThickness
    // Clip to this inset area so sliding panels emerge from *behind* the top bar
    // (and frame) rather than rendering up through it — e.g. the dashboard no
    // longer shows through the picker numbers on the way out.
    clip: true

    Item {
        id: osdWrapper

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: sidebar.width * (1 - sidebar.offsetScale)
        clip: sidebar.visible

        implicitWidth: osd.implicitWidth * (1 - osd.offsetScale)
        implicitHeight: osd.implicitHeight

        Osd.Wrapper {
            id: osd

            screen: root.screen
            visibilities: root.visibilities
            sidebarVisible: sidebar.visible

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
    }

    Notifications.Wrapper {
        id: notifications

        visibilities: root.visibilities
        sidebarPanel: sidebar
        osdPanel: osdWrapper

        anchors.top: parent.top
        anchors.right: parent.right
    }

    Launcher.Wrapper {
        id: launcher

        screen: root.screen
        visibilities: root.visibilities
        panels: root

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }

    Dashboard.Wrapper {
        id: dashboard

        visibilities: root.visibilities
        popouts: popoutsWrapper.content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.dashTabsHeight
    }

    BarPopouts.ClipWrapper {
        id: popoutsWrapper

        screen: root.screen
        borderThickness: root.borderThickness
    }

    Toasts.Toasts {
        id: toasts

        anchors.bottom: parent.bottom
        anchors.right: sidebar.left
        anchors.margins: Tokens.padding.normal
    }

    Sidebar.Wrapper {
        id: sidebar

        visibilities: root.visibilities

        anchors.top: notifications.bottom
        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }
}
