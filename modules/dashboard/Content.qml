pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.filedialog
import qs.modules.popouts as BarPopouts

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property BarPopouts.Wrapper popouts
    readonly property bool needsKeyboard: true
    required property DashboardState dashState
    required property FileDialog facePicker
    required property var dashboardTabs

    function componentFor(id: string): Component {
        switch (id) {
        case "dash":
            return dashComponent;
        case "controls":
            return controlsComponent;
        case "media":
            return mediaComponent;
        case "performance":
            return performanceComponent;
        case "weather":
            return weatherComponent;
        }
        return null;
    }

    readonly property real nonAnimWidth: view.implicitWidth + viewWrapper.anchors.margins * 2
    readonly property real nonAnimHeight: view.implicitHeight + viewWrapper.anchors.margins * 2

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    focus: true
    Component.onCompleted: forceActiveFocus()

    Keys.onPressed: event => {
        if (event.key < Qt.Key_1 || event.key > Qt.Key_9)
            return;
        const idx = event.key - Qt.Key_1;
        if (idx >= root.dashboardTabs.length)
            return;
        root.dashState.currentTab = idx;
        event.accepted = true;
    }

    ClippingRectangle {
        id: viewWrapper

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large

        radius: Tokens.rounding.normal
        color: "transparent"

        Flickable {
            id: view

            readonly property int currentIndex: root.dashState.currentTab
            readonly property Item currentItem: {
                repeater.count; // Trigger update on count change
                return repeater.itemAt(currentIndex);
            }

            anchors.fill: parent

            flickableDirection: Flickable.HorizontalFlick

            implicitWidth: currentItem?.implicitWidth ?? 0
            implicitHeight: currentItem?.implicitHeight ?? 0

            contentX: currentItem?.x ?? 0
            contentWidth: row.implicitWidth
            contentHeight: row.implicitHeight

            onContentXChanged: {
                if (!moving || !currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 2)
                    root.dashState.currentTab = Math.min(root.dashState.currentTab + 1, root.dashboardTabs.length - 1);
                else if (x < -currentItem.implicitWidth / 2)
                    root.dashState.currentTab = Math.max(root.dashState.currentTab - 1, 0);
            }

            onDragEnded: {
                if (!currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 10)
                    root.dashState.currentTab = Math.min(root.dashState.currentTab + 1, root.dashboardTabs.length - 1);
                else if (x < -currentItem.implicitWidth / 10)
                    root.dashState.currentTab = Math.max(root.dashState.currentTab - 1, 0);
                else
                    contentX = Qt.binding(() => currentItem?.x ?? 0);
            }

            RowLayout {
                id: row

                Repeater {
                    id: repeater

                    model: ScriptModel {
                        values: root.dashboardTabs
                    }

                    delegate: Loader {
                        id: paneLoader

                        required property int index
                        required property var modelData

                        Layout.alignment: Qt.AlignTop

                        sourceComponent: root.componentFor(paneLoader.modelData.id)

                        Component.onCompleted: active = Qt.binding(() => {
                            if (index === view.currentIndex)
                                return true;
                            const vx = Math.floor(view.visibleArea.xPosition * view.contentWidth);
                            const vex = Math.floor(vx + view.visibleArea.widthRatio * view.contentWidth);
                            return (vx >= x && vx <= x + implicitWidth) || (vex >= x && vex <= x + implicitWidth);
                        })
                    }
                }
            }

            Component {
                id: dashComponent

                Dash {
                    visibilities: root.visibilities
                    dashState: root.dashState
                    facePicker: root.facePicker
                }
            }

            Component {
                id: controlsComponent

                Controls {
                    visibilities: root.visibilities
                    popouts: root.popouts
                }
            }

            Component {
                id: mediaComponent

                MediaWrapper {
                    visibilities: root.visibilities
                }
            }

            Component {
                id: performanceComponent

                Performance {}
            }

            Component {
                id: weatherComponent

                WeatherTab {}
            }

            Behavior on contentX {
                Anim {}
            }
        }
    }

    Behavior on implicitWidth {
        Anim {
            type: Anim.EmphasizedLarge
        }
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.EmphasizedLarge
        }
    }
}
