pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false

    function toggle(): void {
        const next = !enabled;
        Quickshell.execDetached(["rfkill", next ? "block" : "unblock", "all"]);
        enabled = next;
        refreshTimer.restart();
    }

    function refresh(): void {
        statusProc.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: statusProc

        command: ["rfkill", "--output", "SOFT", "--noheadings"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(l => l.trim().length > 0);
                if (lines.length === 0) {
                    root.enabled = false;
                    return;
                }
                root.enabled = lines.every(line => line.trim() === "blocked");
            }
        }
    }

    Timer {
        id: refreshTimer
        interval: 300
        repeat: false
        onTriggered: root.refresh()
    }
}
