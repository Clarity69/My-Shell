// Entry point. Jalankan:  quickshell -p ~/Documents/Shell
// Toggle:                  quickshell -p ~/Documents/Shell ipc call controlcenter toggle

import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    ControlCenter {
        id: controlCenter
    }

    IpcHandler {
        target: "controlcenter"

        function toggle(): void { controlCenter.toggle() }
        function show(): void   { controlCenter.visible = true }
        function hide(): void   { controlCenter.visible = false }

        // quickshell -p ~/Documents/Shell ipc call controlcenter open network
        function open(page: string): void { controlCenter.openPage(page) }
    }
}
