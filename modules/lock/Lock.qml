pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.components.misc
import qs.services

Scope {
    property alias lock: sessionLock

    WlSessionLock {
        id: sessionLock

        signal unlock

        LockSurface {
            lock: sessionLock
            pam: pam
        }
    }

    Pam {
        id: pam

        lock: sessionLock
    }

    Connections {
        function onLockRequested(): void {
            sessionLock.locked = true;
        }

        function onUnlockRequested(): void {
            sessionLock.unlock();
        }

        target: SessionLock
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "lock"
        description: "Lock the current session"
        onPressed: sessionLock.locked = true
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "unlock"
        description: "Unlock the current session"
        onPressed: sessionLock.unlock()
    }

    IpcHandler {
        function lock(): void {
            sessionLock.locked = true;
        }

        function unlock(): void {
            sessionLock.unlock();
        }

        function isLocked(): bool {
            return sessionLock.locked;
        }

        target: "lock"
    }
}
