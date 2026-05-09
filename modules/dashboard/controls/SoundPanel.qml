pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import qs.utils

Item {
    id: root

    required property var visibilities

    readonly property string title: qsTr("Sound")
    readonly property real minPanelWidth: 720

    implicitWidth: Math.max(contentLayout.implicitWidth, minPanelWidth)
    implicitHeight: contentLayout.implicitHeight

    ColumnLayout {
        id: contentLayout

        anchors.fill: parent
        spacing: Tokens.spacing.large

        SoundCard {
            Layout.fillWidth: true
            title: qsTr("Output")
            volume: Audio.volume
            muted: Audio.muted
            volumeIcon: Icons.getVolumeIcon(Audio.volume, Audio.muted)
            volumeMax: GlobalConfig.services.maxVolume
            devices: Audio.sinks
            currentDeviceId: Audio.sink?.id ?? -1
            deviceIcon: "speaker"
            inactiveDeviceIcon: "speaker_group"
            onVolumeMoved: v => Audio.setVolume(v)
            onMuteToggled: {
                const audio = Audio.sink?.audio;
                if (audio)
                    audio.muted = !audio.muted;
            }
            onDeviceSelected: d => Audio.setAudioSink(d)
        }

        SoundCard {
            Layout.fillWidth: true
            title: qsTr("Input")
            volume: Audio.sourceVolume
            muted: Audio.sourceMuted
            volumeIcon: Icons.getMicVolumeIcon(Audio.sourceVolume, Audio.sourceMuted)
            volumeMax: GlobalConfig.services.maxVolume
            devices: Audio.sources
            currentDeviceId: Audio.source?.id ?? -1
            deviceIcon: "mic"
            inactiveDeviceIcon: "mic"
            onVolumeMoved: v => Audio.setSourceVolume(v)
            onMuteToggled: {
                const audio = Audio.source?.audio;
                if (audio)
                    audio.muted = !audio.muted;
            }
            onDeviceSelected: d => Audio.setAudioSource(d)
        }
    }

    component SoundCard: StyledRect {
        id: card

        property string title
        property real volume
        property bool muted
        property string volumeIcon
        property real volumeMax: 1
        property var devices: []
        property int currentDeviceId: -1
        property string deviceIcon
        property string inactiveDeviceIcon

        signal volumeMoved(real value)
        signal muteToggled
        signal deviceSelected(var device)

        Layout.fillWidth: true
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
                text: card.title
                font.pointSize: Tokens.font.size.normal
                font.weight: 600
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                IconButton {
                    icon: card.muted ? "volume_off" : "volume_up"
                    type: IconButton.Text
                    inactiveOnColour: card.muted ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.large
                    padding: Tokens.padding.small
                    onClicked: card.muteToggled()
                }

                FilledSlider {
                    id: slider

                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    iconText: card.volumeIcon
                    value: card.volume
                    from: 0
                    to: card.volumeMax
                    onMoved: card.volumeMoved(value)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.smaller

                Repeater {
                    model: card.devices

                    delegate: StyledRect {
                        id: row

                        required property var modelData
                        readonly property bool selected: card.currentDeviceId === row.modelData.id

                        Layout.fillWidth: true
                        implicitHeight: rowLayout.implicitHeight + Tokens.padding.normal * 2
                        radius: Tokens.rounding.small
                        color: row.selected ? Colours.layer(Colours.palette.m3surfaceContainer, 2) : "transparent"

                        StateLayer {
                            color: Colours.palette.m3onSurface
                            radius: parent.radius
                            onClicked: card.deviceSelected(row.modelData)
                        }

                        RowLayout {
                            id: rowLayout

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Tokens.padding.normal
                            anchors.rightMargin: Tokens.padding.normal
                            spacing: Tokens.spacing.normal

                            MaterialIcon {
                                text: row.selected ? card.deviceIcon : card.inactiveDeviceIcon
                                color: row.selected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                fill: row.selected ? 1 : 0
                                font.pointSize: Tokens.font.size.large
                                Layout.alignment: Qt.AlignVCenter
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: row.modelData.description || row.modelData.name || qsTr("Unknown")
                                color: row.selected ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                                font.weight: row.selected ? 600 : 400
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }

    component FilledSlider: T.Slider {
        id: slider

        property string iconText
        property real oldValue
        property bool initialized

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

                    text: slider.iconText
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
