pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services

Item {
    id: root

    readonly property var defaultScaleOptions: [1.0, 1.25, 1.5, 1.75, 2.0]
    readonly property var internalScaleOptions: [1.0, 1.25, 1.6, 2.0]

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.large

        StyledText {
            text: qsTr("Display")
            font.pointSize: Tokens.font.size.large
            font.weight: 600
        }

        Repeater {
            model: Brightness.monitors

            delegate: MonitorCard {
                required property var modelData
                Layout.fillWidth: true
                brightnessMonitor: modelData
            }
        }

        Item {
            Layout.fillHeight: true
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

        function applyMonitor(rate: real, scale: real): void {
            const spec = `${card.monitorName},${card.curW}x${card.curH}@${rate.toFixed(2)},${card.curX}x${card.curY},${scale.toFixed(6)}`;
            Quickshell.execDetached(["hyprctl", "keyword", "monitor", spec]);
            refreshTimer.restart();
        }

        Timer {
            id: refreshTimer
            interval: 200
            repeat: false
            onTriggered: Hyprland.refreshMonitors()
        }

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

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.small
                visible: card.rates.length > 0

                MaterialIcon {
                    text: "speed"
                    color: Colours.palette.m3onSurfaceVariant
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    text: qsTr("Refresh")
                    color: Colours.palette.m3onSurface
                    Layout.rightMargin: Tokens.spacing.small
                }

                Repeater {
                    model: card.rates

                    delegate: TextButton {
                        required property var modelData

                        text: `${Math.round(modelData)} Hz`
                        type: TextButton.Tonal
                        toggle: true
                        checked: Math.abs(modelData - card.currentRate) < 0.1
                        onClicked: card.applyMonitor(modelData, card.currentScale)
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: "zoom_in"
                    color: Colours.palette.m3onSurfaceVariant
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    text: qsTr("Scale")
                    color: Colours.palette.m3onSurface
                    Layout.rightMargin: Tokens.spacing.small
                }

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
                        onClicked: card.applyMonitor(card.currentRate, modelData)
                    }
                }

                Item {
                    Layout.fillWidth: true
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
