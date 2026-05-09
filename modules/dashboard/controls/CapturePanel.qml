pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property var visibilities

    readonly property string title: qsTr("Capture")
    readonly property real minPanelWidth: 720

    implicitWidth: Math.max(contentLayout.implicitWidth, minPanelWidth)
    implicitHeight: contentLayout.implicitHeight

    readonly property var recordingExts: ["mp4", "mkv", "webm", "mov"]

    readonly property var combinedEntries: {
        const out = [];
        const seen = new Set();
        const push = (entry, kind) => {
            if (seen.has(entry.path))
                return;
            seen.add(entry.path);
            out.push({
                path: entry.path,
                baseName: entry.baseName,
                kind: kind,
                ts: parseTimestamp(entry.baseName)
            });
        };
        for (const e of screenshotsModel.entries)
            push(e, "screenshot");
        for (const e of recordingsModel.entries) {
            const kind = root.recordingExts.includes(e.suffix.toLowerCase()) ? "recording" : "screenshot";
            push(e, kind);
        }
        out.sort((a, b) => b.ts - a.ts);
        return out.slice(0, 10);
    }

    function parseTimestamp(name: string): real {
        const m = name.match(/(\d{4})(\d{2})(\d{2})[-_](\d{2})-?(\d{2})-?(\d{2})/);
        if (m)
            return new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]).getTime();
        const m2 = name.match(/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/);
        if (m2)
            return new Date(+m2[1], +m2[2] - 1, +m2[3], +m2[4], +m2[5], +m2[6]).getTime();
        return 0;
    }

    function dismissAnd(action): void {
        if (root.visibilities)
            root.visibilities.dashboard = false;
        action();
    }

    function pickerCall(method: string): void {
        Quickshell.execDetached(["qs", "ipc", "--pid", String(Quickshell.processId), "call", "picker", method]);
    }

    FileSystemModel {
        id: screenshotsModel
        path: `${Paths.pictures}/Screenshots`
        filter: FileSystemModel.Images
        watchChanges: true
    }

    FileSystemModel {
        id: recordingsModel
        path: Paths.recsdir
        nameFilters: ["recording_*.mp4"]
        watchChanges: true
    }

    ColumnLayout {
        id: contentLayout

        anchors.fill: parent
        spacing: Tokens.spacing.large

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: screenshotLayout.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: screenshotLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.normal

                StyledText {
                    text: qsTr("Screenshot")
                    font.pointSize: Tokens.font.size.normal
                    font.weight: 600
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    CaptureButton {
                        icon: "fullscreen"
                        text: qsTr("Fullscreen")
                        onClicked: root.dismissAnd(() => Quickshell.execDetached(["sh", "-c", "sleep 0.4 && caelestia screenshot"]))
                    }

                    CaptureButton {
                        icon: "screenshot_region"
                        text: qsTr("Region")
                        onClicked: root.dismissAnd(() => root.pickerCall("open"))
                    }

                    CaptureButton {
                        icon: "ac_unit"
                        text: qsTr("Region (frozen)")
                        onClicked: root.dismissAnd(() => Quickshell.execDetached(["sh", "-c", `sleep 0.4 && qs ipc --pid ${Quickshell.processId} call picker openFreeze`]))
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: recordingLayout.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: recordingLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.normal

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Recording")
                        font.pointSize: Tokens.font.size.normal
                        font.weight: 600
                    }

                    StyledRect {
                        visible: Recorder.running
                        radius: Tokens.rounding.full
                        color: Recorder.paused ? Colours.palette.m3tertiary : Colours.palette.m3error
                        implicitWidth: recBadge.implicitWidth + Tokens.padding.normal * 2
                        implicitHeight: recBadge.implicitHeight + Tokens.padding.smaller * 2

                        StyledText {
                            id: recBadge

                            anchors.centerIn: parent
                            animate: true
                            text: Recorder.paused ? "PAUSED" : "REC"
                            color: Recorder.paused ? Colours.palette.m3onTertiary : Colours.palette.m3onError
                            font.family: Tokens.font.family.mono
                            font.pointSize: Tokens.font.size.smaller
                        }

                        SequentialAnimation on opacity {
                            running: Recorder.running && !Recorder.paused
                            alwaysRunToEnd: true
                            loops: Animation.Infinite

                            Anim {
                                from: 1
                                to: 0
                                duration: Tokens.anim.durations.large
                                easing: Tokens.anim.emphasizedAccel
                            }
                            Anim {
                                from: 0
                                to: 1
                                duration: Tokens.anim.durations.extraLarge
                                easing: Tokens.anim.emphasizedDecel
                            }
                        }
                    }

                    StyledText {
                        visible: Recorder.running
                        text: {
                            const elapsed = Recorder.elapsed;
                            const hours = Math.floor(elapsed / 3600);
                            const mins = Math.floor((elapsed % 3600) / 60);
                            const secs = Math.floor(elapsed % 60).toString().padStart(2, "0");
                            if (hours > 0)
                                return `${hours}:${mins.toString().padStart(2, "0")}:${secs}`;
                            return `${mins}:${secs}`;
                        }
                        font.family: Tokens.font.family.mono
                        font.pointSize: Tokens.font.size.normal
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small
                    visible: !Recorder.running

                    CaptureButton {
                        icon: "fullscreen"
                        text: qsTr("Fullscreen")
                        onClicked: root.dismissAnd(() => Recorder.start())
                    }

                    CaptureButton {
                        icon: "screenshot_region"
                        text: qsTr("Region")
                        onClicked: root.dismissAnd(() => Recorder.start(["-r"]))
                    }

                    CaptureButton {
                        icon: "volume_up"
                        text: qsTr("Fullscreen + Sound")
                        onClicked: root.dismissAnd(() => Recorder.start(["-s"]))
                    }

                    CaptureButton {
                        icon: "graphic_eq"
                        text: qsTr("Region + Sound")
                        onClicked: root.dismissAnd(() => Recorder.start(["-sr"]))
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.normal
                    visible: Recorder.running

                    Item {
                        Layout.fillWidth: true
                    }

                    IconButton {
                        label.animate: true
                        icon: Recorder.paused ? "play_arrow" : "pause"
                        toggle: true
                        checked: Recorder.paused
                        type: IconButton.Tonal
                        font.pointSize: Tokens.font.size.large
                        padding: Tokens.padding.small
                        onClicked: {
                            Recorder.togglePause();
                            internalChecked = Recorder.paused;
                        }
                    }

                    IconButton {
                        icon: "stop"
                        inactiveColour: Colours.palette.m3error
                        inactiveOnColour: Colours.palette.m3onError
                        font.pointSize: Tokens.font.size.large
                        padding: Tokens.padding.small
                        onClicked: Recorder.stop()
                    }
                }
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: recentLayout.implicitHeight + Tokens.padding.large * 2
            radius: Tokens.rounding.normal
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: recentLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.padding.large
                spacing: Tokens.spacing.smaller

                StyledText {
                    text: qsTr("Recent")
                    font.pointSize: Tokens.font.size.normal
                    font.weight: 600
                }

                Loader {
                    Layout.fillWidth: true
                    active: root.combinedEntries.length === 0
                    visible: active

                    sourceComponent: StyledText {
                        text: qsTr("No screenshots or recordings yet")
                        color: Colours.palette.m3outline
                        font.pointSize: Tokens.font.size.small
                    }
                }

                Repeater {
                    model: root.combinedEntries

                    delegate: RowLayout {
                        id: entry

                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Tokens.spacing.smaller

                        MaterialIcon {
                            text: entry.modelData.kind === "recording" ? "movie" : "image"
                            color: Colours.palette.m3onSurfaceVariant
                            font.pointSize: Tokens.font.size.large
                            Layout.alignment: Qt.AlignVCenter
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: entry.modelData.baseName
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        IconButton {
                            icon: entry.modelData.kind === "recording" ? "play_arrow" : "image"
                            type: IconButton.Text
                            padding: Tokens.padding.small
                            font.pointSize: Tokens.font.size.large
                            onClicked: {
                                const cmd = entry.modelData.kind === "recording" ? ["app2unit", "--", ...GlobalConfig.general.apps.playback] : ["xdg-open"];
                                root.dismissAnd(() => Quickshell.execDetached([...cmd, entry.modelData.path]));
                            }
                        }

                        IconButton {
                            icon: "folder"
                            type: IconButton.Text
                            padding: Tokens.padding.small
                            font.pointSize: Tokens.font.size.large
                            onClicked: root.dismissAnd(() => Quickshell.execDetached(["app2unit", "--", ...GlobalConfig.general.apps.explorer, entry.modelData.path]))
                        }

                        IconButton {
                            icon: "delete"
                            type: IconButton.Text
                            padding: Tokens.padding.small
                            font.pointSize: Tokens.font.size.large
                            label.color: Colours.palette.m3error
                            stateLayer.color: Colours.palette.m3error
                            onClicked: Quickshell.execDetached(["trash-put", entry.modelData.path])
                        }
                    }
                }
            }
        }
    }

    component CaptureButton: StyledRect {
        id: btn

        property string icon
        property string text
        signal clicked

        radius: implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
        color: Colours.palette.m3secondaryContainer

        implicitWidth: contentRow.implicitWidth + Tokens.padding.normal * 2
        implicitHeight: contentRow.implicitHeight + Tokens.padding.small * 2

        StateLayer {
            color: Colours.palette.m3onSecondaryContainer
            onClicked: btn.clicked()
        }

        Row {
            id: contentRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.smaller

            MaterialIcon {
                text: btn.icon
                color: Colours.palette.m3onSecondaryContainer
                font.pointSize: Tokens.font.size.normal
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: btn.text
                color: Colours.palette.m3onSecondaryContainer
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
