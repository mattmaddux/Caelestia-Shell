pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property DashboardState dashState
    required property var tabs

    readonly property alias count: bar.count

    implicitHeight: bar.implicitHeight + indicator.implicitHeight + indicator.anchors.topMargin

    TabBar {
        id: bar

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        currentIndex: root.dashState.currentTab
        background: null

        onCurrentIndexChanged: root.dashState.currentTab = currentIndex

        Repeater {
            model: ScriptModel {
                values: root.tabs
            }

            delegate: Tab {
                required property var modelData

                iconName: modelData.iconName
                text: modelData.text
            }
        }
    }

    Item {
        id: indicator

        anchors.top: bar.bottom
        anchors.topMargin: 5

        // width, not implicitWidth: TabBar lays buttons out narrower than
        // their implicit size, and the indicator must match what is drawn
        implicitWidth: {
            // Reading bar.width registers a dependency that actually notifies;
            // TabButton.width does not, so without it this binding evaluates
            // once while the bar is still unlaid-out and sticks at 0
            bar.width;
            const tab = bar.currentItem;
            return tab ? tab.width : 0;
        }
        implicitHeight: 3

        x: bar.x + (bar.currentItem?.x ?? 0)

        clip: true

        StyledRect {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: parent.implicitHeight * 2

            color: Colours.palette.m3primary
            radius: Tokens.rounding.full
        }

        Behavior on x {
            Anim {}
        }

        Behavior on implicitWidth {
            Anim {}
        }
    }

    component Tab: TabButton {
        id: tab

        required property string iconName
        readonly property bool current: TabBar.tabBar.currentItem === this

        background: null

        // The bar no longer stretches to the panel width, so each button has to
        // carry its own breathing room rather than relying on distribution
        leftPadding: Tokens.padding.large
        rightPadding: Tokens.padding.large

        contentItem: CustomMouseArea {
            id: mouse

            function onWheel(event: WheelEvent): void {
                if (event.angleDelta.y < 0)
                    root.dashState.currentTab = Math.min(root.dashState.currentTab + 1, bar.count - 1);
                else if (event.angleDelta.y > 0)
                    root.dashState.currentTab = Math.max(root.dashState.currentTab - 1, 0);
            }

            implicitWidth: Math.max(icon.width, label.width)
            implicitHeight: icon.height + label.height

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onPressed: event => {
                root.dashState.currentTab = tab.TabBar.index;

                const stateY = stateWrapper.y;
                rippleAnim.x = event.x;
                rippleAnim.y = event.y - stateY;

                const dist = (ox, oy) => ox * ox + oy * oy;
                rippleAnim.radius = Math.sqrt(Math.max(dist(event.x, event.y + stateY), dist(event.x, stateWrapper.height - event.y), dist(width - event.x, event.y + stateY), dist(width - event.x, stateWrapper.height - event.y)));

                rippleAnim.restart();
            }

            SequentialAnimation {
                id: rippleAnim

                property real x
                property real y
                property real radius

                PropertyAction {
                    target: ripple
                    property: "x"
                    value: rippleAnim.x
                }
                PropertyAction {
                    target: ripple
                    property: "y"
                    value: rippleAnim.y
                }
                PropertyAction {
                    target: ripple
                    property: "opacity"
                    value: 0.08
                }
                Anim {
                    target: ripple
                    properties: "implicitWidth,implicitHeight"
                    from: 0
                    to: rippleAnim.radius * 2
                    duration: Tokens.anim.durations.normal
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    target: ripple
                    property: "opacity"
                    to: 0
                }
            }

            ClippingRectangle {
                id: stateWrapper

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: parent.height + Tokens.sizes.dashboard.tabIndicatorSpacing * 2

                color: "transparent"
                radius: Tokens.rounding.small

                StyledRect {
                    id: stateLayer

                    anchors.fill: parent

                    color: tab.current ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    opacity: mouse.pressed ? 0.1 : mouse.containsMouse ? 0.08 : 0

                    Behavior on opacity {
                        Anim {}
                    }
                }

                StyledRect {
                    id: ripple

                    radius: Tokens.rounding.full
                    color: tab.current ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    opacity: 0

                    transform: Translate {
                        x: -ripple.width / 2
                        y: -ripple.height / 2
                    }
                }
            }

            MaterialIcon {
                id: icon

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: label.top

                text: tab.iconName
                color: tab.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                fill: tab.current ? 1 : 0
                font.pointSize: Tokens.font.size.large

                Behavior on fill {
                    Anim {}
                }
            }

            StyledText {
                id: label

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom

                text: tab.text
                color: tab.current ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
