//@ pragma UseQApplication
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
import qs.services
import qs.desktop
import qs.island
import qs.launcher

ShellRoot {
    ControlCenter {
        id: controlCenter
    }

    Popups {}
    NotifCenter {}

    Bar {
        onOpenPage: name => controlCenter.openPage(name)
        onToggleControl: controlCenter.toggle()
    }

    Overview {}

    Island {}

    GithubWidget {}
    ClockWidget {}

    // qs -c shell ipc call github refresh
    IpcHandler {
        target: "github"

        function refresh(): void { GitHub.refresh() }
        function toggle(): void  { WidgetSettings.githubShown = !WidgetSettings.githubShown }
    }

    // qs -c shell ipc call notifications toggle
    IpcHandler {
        target: "notifications"

        function toggle(): void { Notifications.toggleCenter() }
        function open(): void   { Notifications.centerOpen = true }
        function close(): void  { Notifications.centerOpen = false }
        function dnd(): void    { Notifications.toggle() }
        function clear(): void  { Notifications.clearAll() }
    }

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

    LauncherWindow {}
    Connections {
        target: Launcher
        function onPageRequested(name) { controlCenter.openPage(name) }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { Launcher.toggle() }
        function open(): void   { Launcher.open = true }
        function close(): void  { Launcher.open = false }
    }
}
