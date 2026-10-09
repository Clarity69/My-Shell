pragma Singleton

import QtQuick
import Quickshell

// Glyph Nerd Font (Material Design, prefix nf-md-).
// Pakai codepoint agar file tetap terbaca di editor tanpa Nerd Font.
Singleton {
    function g(cp) { return String.fromCodePoint(cp) }

    readonly property string user:          g(0xF0004)
    readonly property string search:        g(0xF0349)
    readonly property string refresh:       g(0xF0450)
    readonly property string check:         g(0xF012C)
    readonly property string settings:      g(0xF0493)
    readonly property string arch:          g(0xF08C7)
    readonly property string cpu:           g(0xF0EE0)
    readonly property string memory:        g(0xF035B)

    // Sesi
    readonly property string power:         g(0xF0425)
    readonly property string lock:          g(0xF033E)
    readonly property string logout:        g(0xF0343)
    readonly property string suspend:       g(0xF0904)
    readonly property string reboot:        g(0xF0709)

    // Jaringan
    readonly property string ethernet:      g(0xF0200)
    readonly property string wifi:          g(0xF05A9)
    readonly property string wifiOff:       g(0xF05AA)
    readonly property var wifiStrength:     [g(0xF092F), g(0xF091F), g(0xF0922), g(0xF0925), g(0xF0928)]
    readonly property string bluetooth:     g(0xF00AF)
    readonly property string bluetoothOff:  g(0xF00B2)
    readonly property string bluetoothOn:   g(0xF00B1)

    // Suara & layar
    readonly property string volume:        g(0xF057E)
    readonly property string volumeOff:     g(0xF0581)
    readonly property string speaker:       g(0xF04C3)
    readonly property string mic:           g(0xF036C)
    readonly property string micOff:        g(0xF036D)
    readonly property string brightness:    g(0xF00E0)
    readonly property string night:         g(0xF0594)
    readonly property string monitor:       g(0xF0379)

    // Tampilan
    readonly property string palette:       g(0xF03D8)
    readonly property string image:         g(0xF02E9)
    readonly property string keyboard:      g(0xF030C)
    readonly property string bell:          g(0xF009A)
    readonly property string bellOff:       g(0xF009B)

    // Daya
    readonly property string battery:       g(0xF0079)
    readonly property string charging:      g(0xF0084)
    readonly property string leaf:          g(0xF032A)
    readonly property string balance:       g(0xF05D1)
    readonly property string speed:         g(0xF04C5)
}
