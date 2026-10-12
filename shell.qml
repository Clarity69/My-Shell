// Entry point. Jalankan:  quickshell -p ~/.config/quickshell/shell
// Toggle:                  quickshell -p ~/.config/quickshell/shell ipc call controlcenter toggle
// Bar on/off:              quickshell -p ~/.config/quickshell/shell ipc call bar toggle
// Ganti layout bar:        quickshell -p ~/.config/quickshell/shell ipc call bar layout cozy

import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar
import qs.notifications
import qs.overview

ShellRoot {
    ControlCenter {
        id: controlCenter
    }

    Popups {}

    Bar {
        onOpenPage: name => controlCenter.openPage(name)
        onToggleControl: controlCenter.toggle()
    }

    Overview {}

    // quickshell -c shell ipc call overview toggle
    IpcHandler {
        target: "overview"

        function toggle(): void { OverviewState.toggle() }
        function open(): void   { OverviewState.open() }
        function close(): void  { OverviewState.close() }
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

        // quickshell -p ~/.config/quickshell/shell ipc call controlcenter open network
        function open(page: string): void { controlCenter.openPage(page) }
    }
}
