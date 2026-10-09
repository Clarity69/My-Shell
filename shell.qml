// Entry point. Jalankan:  quickshell -p ~/Documents/Shell
// Toggle:                  quickshell -p ~/Documents/Shell ipc call controlcenter toggle
// Bar on/off:              quickshell -p ~/Documents/Shell ipc call bar toggle
// Ganti layout bar:        quickshell -p ~/Documents/Shell ipc call bar layout cozy

import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

ShellRoot {
    ControlCenter {
        id: controlCenter
    }

    Bar {
        onOpenPage: name => controlCenter.openPage(name)
        onToggleControl: controlCenter.toggle()
    }

    IpcHandler {
        target: "bar"

        function toggle(): void { BarState.shown = !BarState.shown }
        function show(): void   { BarState.shown = true }
        function hide(): void   { BarState.shown = false }

        function layout(name: string): string {
            return BarState.set(name) ? "ok" : "layout tidak dikenal: " + name;
        }
        function next(): string { BarState.next(); return BarState.current; }
        function current(): string { return BarState.current; }
        function layouts(): string { return BarState.names.join("\n"); }
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
