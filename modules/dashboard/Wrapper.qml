pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.modules.popouts as BarPopouts
import qs.utils

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts
    readonly property bool needsKeyboard: (content.item as Content)?.needsKeyboard ?? false
    readonly property DashboardState dashState: DashboardState {
        reloadableId: "dashboardState"
    }
    readonly property FileDialog facePicker: FileDialog {
        title: qsTr("Select a profile picture")
        filterLabel: qsTr("Image files")
        filters: Images.validImageExtensions
        onAccepted: path => {
            if (CUtils.copyFile(Qt.resolvedUrl(path), Qt.resolvedUrl(`${Paths.home}/.face`)))
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "low", "-h", `STRING:image-path:${path}`, "Profile picture changed", `Profile picture changed to ${Paths.shortenHome(path)}`]);
            else
                Quickshell.execDetached(["notify-send", "-a", "caelestia-shell", "-u", "critical", "Unable to change profile picture", `Failed to change profile picture to ${Paths.shortenHome(path)}`]);
        }
    }

    // Tab metadata lives here rather than in Content so the top bar can render
    // the strip without owning the panes. Content resolves id -> Component.
    readonly property var dashboardTabs: {
        const allTabs = [
            {
                id: "dash",
                iconName: "dashboard",
                text: qsTr("Dashboard"),
                enabled: Config.dashboard.showDashboard
            },
            {
                id: "controls",
                iconName: "tune",
                text: qsTr("Controls"),
                enabled: true
            },
            {
                id: "media",
                iconName: "queue_music",
                text: qsTr("Media"),
                enabled: Config.dashboard.showMedia
            },
            {
                id: "performance",
                iconName: "speed",
                text: qsTr("Performance"),
                enabled: Config.dashboard.showPerformance && (Config.dashboard.performance.showCpu || Config.dashboard.performance.showGpu || Config.dashboard.performance.showMemory || Config.dashboard.performance.showStorage || Config.dashboard.performance.showNetwork || Config.dashboard.performance.showBattery)
            },
            {
                id: "weather",
                iconName: "cloud",
                text: qsTr("Weather"),
                enabled: Config.dashboard.showWeather
            }
        ];
        return allTabs.filter(tab => tab.enabled);
    }

    readonly property real nonAnimHeight: state === "visible" ? ((content.item as Content)?.nonAnimHeight ?? 0) : 0
    readonly property bool shouldBeActive: visibilities.dashboard && Config.dashboard.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.topMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 854 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Loader {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            visibilities: root.visibilities
            popouts: root.popouts
            dashState: root.dashState
            facePicker: root.facePicker
            dashboardTabs: root.dashboardTabs
        }
    }
}
