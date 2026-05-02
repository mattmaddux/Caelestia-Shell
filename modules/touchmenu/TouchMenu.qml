pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services

Scope {
    id: root

    LazyLoader {
        id: loader

        property var target

        Surface {
            target: loader.target
            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? null
            onClose: loader.activeAsync = false
        }
    }

    IpcHandler {
        function open(): void {
            const t = Hypr.activeToplevel;
            if (!t)
                return;
            loader.target = t;
            loader.activeAsync = true;
        }

        target: "touchMenu"
    }
}
