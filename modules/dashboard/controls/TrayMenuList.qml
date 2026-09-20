pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services

// A tray item's menu rendered as large, touch-friendly rows. Submenus expand
// inline one level deep rather than opening another surface — tray menus in
// practice are flat or nearly so, and nesting further would out-grow the panel.
ColumnLayout {
    id: root

    required property QsMenuHandle handle

    property int expandedIndex: -1

    signal triggered

    spacing: Tokens.spacing.small / 2

    QsMenuOpener {
        id: opener

        menu: root.handle
    }

    Repeater {
        model: opener.children

        ColumnLayout {
            id: entry

            required property QsMenuEntry modelData
            required property int index

            readonly property bool expanded: root.expandedIndex === entry.index

            Layout.fillWidth: true
            spacing: Tokens.spacing.small / 2

            // Separators are a hairline rather than a row
            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small / 2
                Layout.bottomMargin: Tokens.spacing.small / 2
                visible: entry.modelData.isSeparator

                implicitHeight: 1
                color: Colours.palette.m3outlineVariant
            }

            StyledRect {
                Layout.fillWidth: true
                visible: !entry.modelData.isSeparator

                implicitHeight: entryLabel.implicitHeight + Tokens.padding.small * 2

                radius: Tokens.rounding.normal
                color: entry.expanded ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

                StateLayer {
                    radius: parent.radius
                    disabled: !entry.modelData.enabled

                    onClicked: {
                        if (entry.modelData.hasChildren)
                            root.expandedIndex = entry.expanded ? -1 : entry.index;
                        else {
                            entry.modelData.triggered();
                            root.triggered();
                        }
                    }
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.normal
                    anchors.rightMargin: Tokens.padding.normal

                    spacing: Tokens.spacing.normal

                    Loader {
                        asynchronous: true
                        active: (entry.modelData?.icon ?? "") !== ""

                        sourceComponent: IconImage {
                            asynchronous: true
                            implicitSize: entryLabel.implicitHeight
                            source: entry.modelData?.icon ?? ""
                        }
                    }

                    StyledText {
                        id: entryLabel

                        Layout.fillWidth: true
                        text: entry.modelData.text
                        color: entry.modelData.enabled ? Colours.palette.m3onSurface : Colours.palette.m3outline
                        elide: Text.ElideRight
                    }

                    MaterialIcon {
                        visible: entry.modelData.hasChildren
                        animate: true
                        text: entry.expanded ? "expand_more" : "chevron_right"
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }

            // Submenu children, indented, revealed in place. Kept out of the
            // layout entirely when absent so flat menus don't pay for spacing
            // around a zero-height item on every row.
            WrapperItem {
                Layout.fillWidth: true
                Layout.leftMargin: Tokens.padding.large
                Layout.preferredHeight: entry.expanded ? implicitHeight : 0

                visible: entry.modelData.hasChildren
                clip: true

                ColumnLayout {
                    spacing: Tokens.spacing.small / 2

                    QsMenuOpener {
                        id: subOpener

                        menu: entry.modelData.hasChildren ? entry.modelData : null
                    }

                    Repeater {
                        model: subOpener.children

                        StyledRect {
                            id: subEntry

                            required property QsMenuEntry modelData

                            Layout.fillWidth: true
                            visible: !subEntry.modelData.isSeparator
                            implicitHeight: subLabel.implicitHeight + Tokens.padding.small * 2

                            radius: Tokens.rounding.normal
                            color: Colours.tPalette.m3surfaceContainer

                            StateLayer {
                                radius: parent.radius
                                disabled: !subEntry.modelData.enabled

                                onClicked: {
                                    subEntry.modelData.triggered();
                                    root.triggered();
                                }
                            }

                            StyledText {
                                id: subLabel

                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: Tokens.padding.normal
                                anchors.rightMargin: Tokens.padding.normal

                                text: subEntry.modelData.text
                                color: subEntry.modelData.enabled ? Colours.palette.m3onSurface : Colours.palette.m3outline
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Behavior on Layout.preferredHeight {
                    Anim {}
                }
            }
        }
    }
}
