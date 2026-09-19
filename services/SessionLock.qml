pragma Singleton

import Quickshell

// Decouples "something wants the session locked" from the WlSessionLock itself,
// which lives in modules/lock/Lock.qml because it owns the LockSurface tree.
// UI can call SessionLock.lock() directly instead of spawning the CLI to IPC
// back into this same process.
Singleton {
    id: root

    signal lockRequested
    signal unlockRequested

    function lock(): void {
        root.lockRequested();
    }

    function unlock(): void {
        root.unlockRequested();
    }
}
