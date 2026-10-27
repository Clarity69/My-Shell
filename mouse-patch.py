# Wires MouseBattery into My Shell: Config options, bar module "mouse", Power page row.
# Safe to run twice; makes .bak copies first.
import os, shutil, sys
os.chdir(os.path.expanduser("~/.config/quickshell/shell"))
files = ["config/Config.qml", "bar/Module.qml", "bar/BarState.qml", "pages/PowerPage.qml"]
for f in files:
    os.chmod(f, 0o644)
    shutil.copy(f, f + ".bak")

def last_brace_insert(s, add):
    i = s.rstrip().rfind("}")
    return s[:i] + add + s[i:]

# Config
p = "config/Config.qml"; s = open(p).read()
if "mouseBattery" not in s:
    s = last_brace_insert(s, '''
    // ── Mouse battery (2.4 GHz YJX-CHIP receiver, bin/mouse-battery) ──
    readonly property bool mouseBattery: true
    readonly property string mouseBatteryScript: home + "/.config/quickshell/shell/bin/mouse-battery"
    readonly property int mouseBatteryInterval: 60       // seconds
    readonly property int mouseLowBattery: 15            // percent, warns once below this
''')
open(p, "w").write(s)

# Module.qml
p = "bar/Module.qml"; s = open(p).read()
if "mouseC" not in s:
    # register in comps
    i = s.index("readonly property var comps: ({")
    j = s.index("})", i)
    body = s[i:j].rstrip()
    s = s[:i] + body + ",\n        mouse: mouseC\n    " + s[j:]
    # hide when no receiver
    s = s.replace("visible: ({", "visible: ({\n        mouse: MouseBattery.available,", 1)
    comp = '''    // Mouse battery: click = read now, dimmed while the mouse sleeps
    Component {
        id: mouseC
        BarItem {
            icon: MouseBattery.charging ? Icons.charging : String.fromCodePoint(0xF037D)
            label: MouseBattery.level + "%"
            dimmed: MouseBattery.asleep
            iconColor: MouseBattery.level <= Config.mouseLowBattery && !MouseBattery.charging ? Theme.danger : Theme.text
            onClicked: MouseBattery.refresh()
        }
    }

'''
    k = s.index("    Component {\n        id: launcherC")
    s = s[:k] + comp + s[k:]
open(p, "w").write(s)

# BarState module list comment
p = "bar/BarState.qml"; s = open(p).read()
if " mouse" not in s.split("Singleton {")[0]:
    s = s.replace(" weather\n", " weather mouse\n", 1)
open(p, "w").write(s)

# Power page
p = "pages/PowerPage.qml"; s = open(p).read()
if "MouseBattery" not in s:
    row = '''    InfoRow {
        visible: MouseBattery.available
        key: "mouse"
        value: MouseBattery.level + "%" + (MouseBattery.charging ? "  ·  charging" : "")
               + (MouseBattery.asleep ? "  ·  asleep" : "")
    }

'''
    marker = "    // ── Power profile"
    if marker in s:
        k = s.index(marker); s = s[:k] + row + s[k:]
    else:
        s = last_brace_insert(s, "\n" + row)
open(p, "w").write(s)
print("done")
