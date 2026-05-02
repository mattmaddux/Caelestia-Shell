pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

PanelWindow {
    id: root

    required property var target
    required property ShellScreen screen

    signal close

    screen: root.screen
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function findClientAt(x: real, y: real): var {
        const sx = root.screen.x;
        const sy = root.screen.y;
        for (const c of Hypr.toplevels.values) {
            if (!c?.lastIpcObject)
                continue;
            const at = c.lastIpcObject.at;
            const size = c.lastIpcObject.size;
            const cx = at[0] - sx;
            const cy = at[1] - sy;
            if (x >= cx && x <= cx + size[0] && y >= cy && y <= cy + size[1])
                return c;
        }
        return null;
    }

    function doSwap(targetClient: var): void {
        if (!root.target || !targetClient || targetClient.address === root.target.address) {
            root.close();
            return;
        }
        const sa = root.target.lastIpcObject;
        const tb = targetClient.lastIpcObject;
        const dx = (tb.at[0] + tb.size[0] / 2) - (sa.at[0] + sa.size[0] / 2);
        const dy = (tb.at[1] + tb.size[1] / 2) - (sa.at[1] + sa.size[1] / 2);
        const dir = Math.abs(dx) > Math.abs(dy)
            ? (dx < 0 ? "l" : "r")
            : (dy < 0 ? "u" : "d");
        Hypr.dispatch(`focuswindow address:0x${root.target.address}`);
        Hypr.dispatch(`swapwindow ${dir}`);
        root.close();
    }

    HyprlandFocusGrab {
        active: true
        windows: [root]
        onCleared: root.close()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: mouse => {
            if (content.mode === 2) {
                const t = root.findClientAt(mouse.x, mouse.y);
                if (t)
                    root.doSwap(t);
                else
                    root.close();
            } else {
                root.close();
            }
        }
    }

    Content {
        id: content

        target: root.target
        screen: root.screen
        onClose: root.close()

        x: {
            if (!root.target?.lastIpcObject)
                return (root.width - width) / 2;
            const at = root.target.lastIpcObject.at;
            const size = root.target.lastIpcObject.size;
            return at[0] - root.screen.x + size[0] / 2 - width / 2;
        }
        y: {
            if (!root.target?.lastIpcObject)
                return (root.height - height) / 2;
            const at = root.target.lastIpcObject.at;
            const size = root.target.lastIpcObject.size;
            return at[1] - root.screen.y + size[1] / 2 - height / 2;
        }
    }
}
