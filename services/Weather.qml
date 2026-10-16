pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Cuaca dari Open-Meteo lewat bin/weather (JSON cache). Cache langsung dipakai saat start.
Singleton {
    id: root

    property bool available: false
    property string city: ""
    property real temp: 0
    property real feels: 0
    property int humidity: 0
    property real wind: 0
    property int code: 0
    property bool isDay: true
    property var daily: []          // [{ date: Date, code, max, min, rain }]
    property bool loading: false
    property string error: ""

    readonly property string icon: iconFor(code, isDay)
    readonly property string description: describe(code)

    function refresh() {
        if (proc.running || !Config.weatherEnabled) return;
        loading = true;
        error = "";
        proc.running = true;
    }

    // Kode cuaca WMO -> ikon Nerd Font
    function iconFor(c, day) {
        const g = cp => String.fromCodePoint(cp);
        if (c === 0) return day ? g(0xF0599) : g(0xF0594);                 // cerah
        if (c <= 2) return day ? g(0xF0595) : g(0xF0F31);                  // cerah berawan
        if (c === 3) return g(0xF0590);                                    // mendung
        if (c === 45 || c === 48) return g(0xF0591);                       // kabut
        if (c >= 95) return g(0xF067E);                                    // badai petir
        if (c === 65 || c === 82) return g(0xF0596);                       // hujan lebat
        if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return g(0xF0597); // hujan / gerimis
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return g(0xF059A); // salju
        return g(0xF0590);
    }

    function describe(c) {
        if (c === 0) return "Clear";
        if (c === 1) return "Mostly clear";
        if (c === 2) return "Partly cloudy";
        if (c === 3) return "Overcast";
        if (c === 45 || c === 48) return "Fog";
        if (c >= 51 && c <= 57) return "Drizzle";
        if (c === 65) return "Heavy rain";
        if (c >= 61 && c <= 67) return "Rain";
        if (c >= 71 && c <= 77) return "Snow";
        if (c >= 80 && c <= 82) return "Rain showers";
        if (c === 85 || c === 86) return "Snow showers";
        if (c >= 95) return "Thunderstorm";
        return "—";
    }

    function parse(raw) {
        let j;
        try { j = JSON.parse(raw); } catch (e) { return; }
        if (!j.current) return;

        city = Config.weatherCity !== "" ? Config.weatherCity : (j.city ?? "");
        temp = j.current.temperature_2m;
        feels = j.current.apparent_temperature;
        humidity = j.current.relative_humidity_2m;
        wind = j.current.wind_speed_10m;
        code = j.current.weather_code;
        isDay = j.current.is_day === 1;

        const d = j.daily ?? {};
        const out = [];
        for (let i = 0; i < (d.time ?? []).length; i++) {
            const [y, m, dd] = d.time[i].split("-").map(Number);
            out.push({
                date: new Date(y, m - 1, dd),
                code: d.weather_code[i],
                max: d.temperature_2m_max[i],
                min: d.temperature_2m_min[i],
                rain: d.precipitation_probability_max?.[i] ?? 0
            });
        }
        daily = out;
        available = true;
    }

    FileView {
        path: Config.weatherCache
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }

    Process {
        id: proc
        command: [Config.weatherScript, Config.weatherLat, Config.weatherLon, Config.weatherCity, Config.weatherCache]
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") root.error = text.trim().split("\n").pop()
        }
        onExited: root.loading = false
    }

    Timer {
        interval: Math.max(10, Config.weatherRefreshMinutes) * 60 * 1000
        repeat: true
        running: Config.weatherEnabled
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
