pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

Item {
    id: root

    readonly property string title: qsTr("Display")
    readonly property var defaultScaleOptions: [1.0, 1.25, 1.5, 1.75, 2.0]
    readonly property var internalScaleOptions: [1.0, 1.25, 1.6, 2.0]

    readonly property real minPanelWidth: 720
    readonly property real maxPanelWidth: 960

    property var disabledMonitors: []

    implicitWidth: Math.max(Math.min(contentLayout.implicitWidth, maxPanelWidth), minPanelWidth)
    implicitHeight: contentLayout.implicitHeight

    Component.onCompleted: allMonitorsProc.running = true

    Connections {
        target: Hyprland
        function onRawEvent(event): void {
            const n = event.name;
            if (n.includes("mon"))
                allMonitorsProc.running = true;
        }
    }

    Process {
        id: allMonitorsProc

        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const all = JSON.parse(text);
                    const activeNames = Brightness.monitors.map(m => m.modelData.name);
                    root.disabledMonitors = all.filter(m => m.disabled || !activeNames.includes(m.name));
                } catch (e) {
                    root.disabledMonitors = [];
                }
            }
        }
    }

    ColumnLayout {
        id: contentLayout

        anchors.fill: parent
        spacing: Tokens.spacing.large

        Repeater {
            model: Brightness.monitors

            delegate: MonitorCard {
                required property var modelData
                Layout.fillWidth: true
                brightnessMonitor: modelData
            }
        }

        Repeater {
            model: root.disabledMonitors

            delegate: DisabledCard {
                required property var modelData
                Layout.fillWidth: true
                ipc: modelData
            }
        }
    }

    component ControlRow: RowLayout {
        id: row

        property string icon
        property string label
        default property alias content: flow.data

        Layout.topMargin: Tokens.spacing.small
        spacing: Tokens.spacing.small

        Item {
            Layout.preferredWidth: 130
            Layout.preferredHeight: labelGroup.height
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: Tokens.padding.smaller

            Row {
                id: labelGroup

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: row.icon
                    color: Colours.palette.m3onSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: row.label
                    color: Colours.palette.m3onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Flow {
            id: flow
            Layout.fillWidth: true
            spacing: Tokens.spacing.small
        }
    }

    component DisabledCard: StyledRect {
        id: disabledCard

        required property var ipc
        readonly property string monitorName: disabledCard.ipc?.name ?? ""
        readonly property string description: disabledCard.ipc?.model ?? ""

        function enableMonitor(): void {
            Quickshell.execDetached(["hyprctl", "keyword", "monitor", `${disabledCard.monitorName},preferred,auto,auto`]);
            allMonitorsProc.running = true;
            Hyprland.refreshMonitors();
        }

        implicitWidth: disabledLayout.implicitWidth + Tokens.padding.large * 2
        implicitHeight: disabledLayout.implicitHeight + Tokens.padding.large * 2
        radius: Tokens.rounding.normal
        color: Colours.tPalette.m3surfaceContainer
        opacity: 0.7

        RowLayout {
            id: disabledLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.normal

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.smaller

                StyledText {
                    Layout.fillWidth: true
                    text: disabledCard.description ? `${disabledCard.monitorName}  ·  ${disabledCard.description}` : disabledCard.monitorName
                    font.pointSize: Tokens.font.size.normal
                    font.weight: 600
                    elide: Text.ElideRight
                }

                StyledText {
                    text: qsTr("Disabled")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.smaller
                }
            }

            TextButton {
                text: qsTr("Enable")
                type: TextButton.Tonal
                onClicked: disabledCard.enableMonitor()
            }
        }
    }

    component MonitorCard: StyledRect {
        id: card

        required property var brightnessMonitor

        readonly property var hyprMonitor: Hyprland.monitorFor(card.brightnessMonitor.modelData)
        readonly property var ipc: card.hyprMonitor?.lastIpcObject ?? null
        readonly property string monitorName: card.brightnessMonitor.modelData.name
        readonly property string description: card.brightnessMonitor.modelData.model ?? ""
        readonly property bool isInternal: card.monitorName.startsWith("eDP")
        readonly property bool supportsBrightness: card.brightnessMonitor.isDdc || card.isInternal
        readonly property var scaleOptions: card.isInternal ? root.internalScaleOptions : root.defaultScaleOptions
        readonly property real currentBrightness: card.brightnessMonitor.brightness
        readonly property real currentRate: card.ipc?.refreshRate ?? 0
        readonly property real currentScale: card.ipc?.scale ?? 1.0
        readonly property int curW: card.ipc?.width ?? 0
        readonly property int curH: card.ipc?.height ?? 0
        readonly property int curX: card.ipc?.x ?? 0
        readonly property int curY: card.ipc?.y ?? 0
        readonly property var availableModes: card.ipc?.availableModes ?? []
        readonly property int currentTransform: card.ipc?.transform ?? 0
        readonly property bool currentVrr: card.ipc?.vrr ?? false
        readonly property string currentMirror: card.ipc?.mirrorOf ?? ""
        readonly property bool isMirroring: card.currentMirror !== "" && card.currentMirror !== "none"
        readonly property var rates: {
            const set = new Map();
            for (const mode of card.availableModes) {
                const m = mode.match(/^(\d+)x(\d+)@([\d.]+)Hz$/);
                if (!m)
                    continue;
                if (parseInt(m[1]) === card.curW && parseInt(m[2]) === card.curH) {
                    const rate = parseFloat(m[3]);
                    const key = Math.round(rate * 100);
                    if (!set.has(key))
                        set.set(key, rate);
                }
            }
            return Array.from(set.values()).sort((a, b) => b - a);
        }
        readonly property var resolutions: {
            const set = new Map();
            for (const mode of card.availableModes) {
                const m = mode.match(/^(\d+)x(\d+)@/);
                if (!m)
                    continue;
                const w = parseInt(m[1]);
                const h = parseInt(m[2]);
                const key = `${w}x${h}`;
                if (!set.has(key))
                    set.set(key, { w, h });
            }
            return Array.from(set.values()).sort((a, b) => b.w * b.h - a.w * a.h);
        }
        readonly property var otherMonitors: {
            const out = [];
            for (const m of Brightness.monitors) {
                const n = m.modelData.name;
                if (n !== card.monitorName)
                    out.push(n);
            }
            return out;
        }

        function bestRateFor(w: int, h: int): real {
            let best = 0;
            for (const mode of card.availableModes) {
                const m = mode.match(/^(\d+)x(\d+)@([\d.]+)Hz$/);
                if (!m)
                    continue;
                if (parseInt(m[1]) === w && parseInt(m[2]) === h) {
                    const r = parseFloat(m[3]);
                    if (r > best)
                        best = r;
                }
            }
            return best;
        }

        function applyMonitor(opts): void {
            const next = Object.assign({
                rate: card.currentRate,
                scale: card.currentScale,
                w: card.curW,
                h: card.curH,
                x: card.curX,
                y: card.curY,
                transform: card.currentTransform,
                vrr: card.currentVrr ? 1 : 0,
                mirror: card.currentMirror
            }, opts);
            let spec = `${card.monitorName},${next.w}x${next.h}@${next.rate.toFixed(2)},${next.x}x${next.y},${next.scale.toFixed(6)}`;
            spec += `,transform,${next.transform}`;
            spec += `,vrr,${next.vrr}`;
            if (next.mirror && next.mirror !== "none")
                spec += `,mirror,${next.mirror}`;
            Quickshell.execDetached(["hyprctl", "keyword", "monitor", spec]);
            refreshTimer.restart();
        }

        function disableMonitor(): void {
            Quickshell.execDetached(["hyprctl", "keyword", "monitor", `${card.monitorName},disable`]);
            refreshTimer.restart();
        }

        Timer {
            id: refreshTimer
            interval: 200
            repeat: false
            onTriggered: {
                Hyprland.refreshMonitors();
                allMonitorsProc.running = true;
            }
        }

        implicitWidth: cardLayout.implicitWidth + Tokens.padding.large * 2
        implicitHeight: cardLayout.implicitHeight + Tokens.padding.large * 2
        radius: Tokens.rounding.normal
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: cardLayout

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.normal

            StyledText {
                Layout.fillWidth: true
                text: card.description ? `${card.monitorName}  ·  ${card.description}` : card.monitorName
                font.pointSize: Tokens.font.size.normal
                font.weight: 600
                elide: Text.ElideRight
            }

            BrightnessSlider {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                visible: card.supportsBrightness
                value: card.currentBrightness
                onMoved: card.brightnessMonitor.setBrightness(value)
            }

            ControlRow {
                Layout.fillWidth: true
                icon: "aspect_ratio"
                label: qsTr("Resolution")
                visible: card.resolutions.length > 0 && !card.isMirroring

                Repeater {
                    model: card.resolutions

                    delegate: TextButton {
                        required property var modelData

                        text: `${modelData.w}×${modelData.h}`
                        type: TextButton.Tonal
                        toggle: true
                        checked: modelData.w === card.curW && modelData.h === card.curH
                        onClicked: {
                            const newRate = card.bestRateFor(modelData.w, modelData.h);
                            card.applyMonitor({
                                w: modelData.w,
                                h: modelData.h,
                                rate: newRate
                            });
                        }
                    }
                }
            }

            ControlRow {
                Layout.fillWidth: true
                icon: "speed"
                label: qsTr("Refresh")
                visible: card.rates.length > 0 && !card.isMirroring

                Repeater {
                    model: card.rates

                    delegate: TextButton {
                        required property var modelData

                        text: `${Math.round(modelData)} Hz`
                        type: TextButton.Tonal
                        toggle: true
                        checked: Math.abs(modelData - card.currentRate) < 0.1
                        onClicked: card.applyMonitor({ rate: modelData })
                    }
                }
            }

            ControlRow {
                Layout.fillWidth: true
                icon: "zoom_in"
                label: qsTr("Scale")
                visible: !card.isMirroring

                Repeater {
                    model: card.scaleOptions

                    delegate: TextButton {
                        required property var modelData

                        readonly property real closestPreset: {
                            let best = card.scaleOptions[0];
                            let bestDist = Math.abs(best - card.currentScale);
                            for (const opt of card.scaleOptions) {
                                const d = Math.abs(opt - card.currentScale);
                                if (d < bestDist) {
                                    bestDist = d;
                                    best = opt;
                                }
                            }
                            return best;
                        }

                        text: `${modelData.toFixed(2)}×`
                        type: TextButton.Tonal
                        toggle: true
                        checked: modelData === closestPreset
                        onClicked: card.applyMonitor({ scale: modelData })
                    }
                }
            }

            ControlRow {
                Layout.fillWidth: true
                icon: "screen_rotation"
                label: qsTr("Rotation")
                visible: !card.isMirroring

                Repeater {
                    model: [
                        { value: 0, text: "0°" },
                        { value: 1, text: "90°" },
                        { value: 2, text: "180°" },
                        { value: 3, text: "270°" }
                    ]

                    delegate: TextButton {
                        required property var modelData

                        text: modelData.text
                        type: TextButton.Tonal
                        toggle: true
                        checked: modelData.value === card.currentTransform
                        onClicked: card.applyMonitor({ transform: modelData.value })
                    }
                }
            }

            ControlRow {
                Layout.fillWidth: true
                icon: "screen_share"
                label: qsTr("Mirror")
                visible: card.otherMonitors.length > 0

                TextButton {
                    text: qsTr("Off")
                    type: TextButton.Tonal
                    toggle: true
                    checked: !card.isMirroring
                    onClicked: card.applyMonitor({ mirror: "" })
                }

                Repeater {
                    model: card.otherMonitors

                    delegate: TextButton {
                        required property var modelData

                        text: modelData
                        type: TextButton.Tonal
                        toggle: true
                        checked: card.currentMirror === modelData
                        onClicked: card.applyMonitor({ mirror: modelData })
                    }
                }
            }

            ControlRow {
                Layout.fillWidth: true
                icon: "power_settings_new"
                label: qsTr("Display")

                TextButton {
                    text: qsTr("On")
                    type: TextButton.Tonal
                    toggle: false
                    checked: true
                    onClicked: {}
                }

                TextButton {
                    text: qsTr("Off")
                    type: TextButton.Tonal
                    toggle: false
                    checked: false
                    visible: card.otherMonitors.length > 0
                    onClicked: card.disableMonitor()
                }
            }
        }
    }

    component BrightnessSlider: T.Slider {
        id: slider

        property real oldValue
        property bool initialized

        from: 0
        to: 1

        background: StyledRect {
            color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
            radius: Tokens.rounding.full

            StyledRect {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left

                implicitWidth: slider.handle.x + slider.handle.implicitWidth

                color: Colours.palette.m3secondary
                radius: parent.radius
            }
        }

        handle: Item {
            id: handleItem

            property alias moving: handleIcon.moving

            x: slider.visualPosition * (slider.availableWidth - width)
            implicitWidth: slider.height
            implicitHeight: slider.height

            Elevation {
                anchors.fill: parent
                radius: handleRect.radius
                level: handleArea.containsMouse ? 2 : 1
            }

            StyledRect {
                id: handleRect

                anchors.fill: parent
                color: Colours.palette.m3inverseSurface
                radius: Tokens.rounding.full

                MouseArea {
                    id: handleArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.NoButton
                }

                MaterialIcon {
                    id: handleIcon

                    property bool moving

                    function update(): void {
                        animate = !moving;
                        binding.when = moving;
                        font.pointSize = moving ? Tokens.font.size.small : Tokens.font.size.larger;
                        font.family = moving ? Tokens.font.family.sans : Tokens.font.family.material;
                    }

                    text: `brightness_${(Math.round(slider.value * 6) + 1)}`
                    color: Colours.palette.m3inverseOnSurface
                    anchors.centerIn: parent

                    onMovingChanged: handleAnim.restart()

                    Binding {
                        id: binding

                        target: handleIcon
                        property: "text"
                        value: Math.round(slider.value * 100)
                        when: false
                    }

                    SequentialAnimation {
                        id: handleAnim

                        Anim {
                            target: handleIcon
                            property: "scale"
                            to: 0
                            duration: Tokens.anim.durations.normal / 2
                            easing: Tokens.anim.standardAccel
                        }
                        ScriptAction {
                            script: handleIcon.update()
                        }
                        Anim {
                            target: handleIcon
                            property: "scale"
                            to: 1
                            duration: Tokens.anim.durations.normal / 2
                            easing: Tokens.anim.standardDecel
                        }
                    }
                }
            }
        }

        onPressedChanged: handle.moving = pressed

        onValueChanged: {
            if (!initialized) {
                initialized = true;
                return;
            }
            if (Math.abs(value - oldValue) < 0.01)
                return;
            oldValue = value;
            handle.moving = true;
            stateChangeDelay.restart();
        }

        Timer {
            id: stateChangeDelay

            interval: 500
            onTriggered: {
                if (!slider.pressed)
                    slider.handle.moving = false;
            }
        }

        Behavior on value {
            Anim {
                type: Anim.StandardLarge
            }
        }
    }
}
