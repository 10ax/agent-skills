# Verification transcripts

Concrete commands and the output they produce, so you know what "verified" looks
like for a plasmoid. All of this works headlessly, which matters because the
popup is usually not openable from a terminal.

## 1. qmllint

`qmllint` is often not on `PATH` on Arch; it lives in `/usr/lib/qt6/bin`.

```sh
qmllint -I /usr/lib/qt6/qml contents/ui/main.qml
# every i18n("...") is reported as "Unqualified access" - a false positive,
# because plasmashell injects i18n at runtime. Filtering the whole warning
# class also hides a typo'd id or property, which is the same warning text.
# Filter by source line: see SKILL.md for the awk one-liner, and prove the
# filter still fails on a deliberate `property int broken: bodyy`.
```

Exit status is not a substitute for looking at the output: `qmllint` on six clean
files exits 0 while still printing ~39 `Unqualified access` lines. The pipeline
above elides them; a real `missing-property`/`is not a type`/`Expected token`
line is *not* elided and is what the check is for.

## 2. Offline layout probe

```sh
QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 timeout 20 qml6 probe-layout.qml
```

`QT_FORCE_STDERR_LOGGING=1` is required — without it `console.log` produces no
output at all and it looks like the probe silently failed.

Real output from the bug where the bars collapsed to a dot:

```
qml: gridUnit 18
qml: body implicitHeight 180 height 180
qml: row 0 labelW 263 trackW 1 fillW 11 pctW 108
qml: row 1 labelW 263 trackW 1 fillW 11 pctW 108
qml: row 2 labelW 263 trackW 1 fillW 11 pctW 108
```

`trackW 1` with `labelW 263` is the signature: the un-elided "Resets in …" label
set a 263 px implicit width, the row gave the label column all the space, and the
`Layout.fillWidth` bar got 1 px (the fill then rendered at its 11 px minimum =
the unexplained green dot).

After capping the column with `Layout.maximumWidth` and giving the bar
`Layout.minimumWidth`:

```
qml: row 0 labelW 126 trackW 90 fillW 11     pctW 90
qml: row 1 labelW 126 trackW 90 fillW 11     pctW 90
qml: row 2 labelW 126 trackW 90 fillW 37.29  pctW 90
```

Now the fill scales with the percentage and every row's track is identical, so
the bars line up.

## 3. Popup padding vs height

`PlasmaExtras.Representation` is a `Page`, so it can be instantiated outside
plasmashell — the theme-derived padding will be 0 there (no `AppletPopup`
window), but explicit padding and the implicit-size arithmetic are real:

```sh
QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 qml6 repprobe.qml
```

```
qml: body.implicitHeight 185
qml: rep.implicitHeight 201
qml: rep.topPadding 8 bottomPadding 8
qml: Layout.minimumHeight 201
qml: paddingIncludedInImplicit true
```

Lesson: setting explicit padding is not enough. If the popup ends up sized from
the content alone, the last row is clipped by exactly the padding. Bind

```qml
Layout.minimumHeight: body.implicitHeight + topPadding + bottomPadding
```

`PlasmaQuick::AppletPopup::updateMinSize` honours `Layout.minimumHeight`
(confirmed by symbols in `libPlasmaQuick.so`:
`AppletPopup::updateMinSize`, `updateMaxSize`, `updateSize`), so this is the
property that fixes it.

## 4. Does the real applet load?

### 4a. `plasmawindowed` — the cheap one, do this first

`plasmawindowed` ships with plasma-workspace, so it is already installed (unlike
`plasmoidviewer`, which needs plasma-sdk). It runs an **installed** widget in a
window, and for a `PlasmoidItem` it instantiates the full representation:

```sh
timeout 10 plasmawindowed org.example.widget      # rc=124 == it stayed up
journalctl --user --since "20 seconds ago" --no-pager | grep -i 'example'
```

Measured on 6.7.5 with a widget whose popup body was being refactored (a
disposable copy of the package with `console.log` lines added to `main.qml`,
`UsageBody.qml` and `MeterRow.qml`):

```
plasmawindowed[2121674]: PROBE-MAIN instantiated
plasmawindowed[2121674]: PROBE-USAGEBODY instantiated
plasmawindowed[2121674]: PROBE-METERROW instantiated
plasmawindowed[2121674]: PROBE-METERROW instantiated
plasmawindowed[2121674]: PROBE-METERROW instantiated      # one per visible meter
```

Three facts worth remembering:

- **`console.log` from a plasmoid goes to the user journal, not to the process's
  stdout.** `plasmawindowed … 2>&1 | head` printed *nothing* (0 bytes) for the
  same run that produced the five journal lines above. `QT_LOGGING_RULES=
  "qml.debug=true"` made no difference to journal delivery — measured with and
  without, 5 lines either way — so reach for `journalctl --user`, not the pipe.
- It **populates the repeater**, so a `required property` that the shell forgets
  to pass, or a component that fails to resolve, shows up as an error/blank here.
- It leaves no trace: no tray popup, no plasmashell restart, nothing on screen
  after it exits. Killing it (`pkill -f plasmawindowed`) is fine; config it wrote
  lives in the appletsrc as a normal applet group.

The disposable-probe-package recipe, when you need proof of *which* pieces load
(never edit the real installed copy for this):

```sh
probe=~/.local/share/plasma/plasmoids/org.example.widget.probe
cp -r <src>/contents "$probe/"                       # plus metadata.json with the
# Id/Name rewritten to *.probe — use sed, then check `kpackagetool6 --list`
# add `Component.onCompleted: console.log("PROBE-X instantiated")` to each file of interest
timeout 10 plasmawindowed org.example.widget.probe
journalctl --user --since "30 seconds ago" --no-pager | grep PROBE-
rm -rf "$probe"                                       # clean up afterwards
```

Note the widget's own applet must be installed for `plasmawindowed`, since it
resolves by plugin id.

### 4b. Add it to a panel (or the desktop), then remove it

The user's panel is left as it was.

```sh
# read-only first: what panels exist
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
  'var out=""; for (var i=0;i<panels().length;i++){ out += "panel "+i+" id="+panels()[i].id+"\n"; } print(out);'

# add, capture the id
ID=$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
  'var p=panels()[0]; var a=p.addWidget("org.example.widget"); print(a.id);' | tail -1)

# did it actually run its helper? note the [b]racket: without it pgrep matches
# its own command line and you get a false positive.
pgrep -af '[o]pencode-go-usage json'

# any QML errors?
journalctl --user -u plasma-plasmashell --since "20 seconds ago" --no-pager \
  | grep -iE 'widget|main\.qml|is not a|undefined|ReferenceError|binding loop'

# clean up
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
  "var p=panels()[0]; var w=p.widgetById($ID); if(w){w.remove(); print('removed');}"
```

Useful facts learned the hard way:

- **Read-only alternative** when you must not add/remove the widget (or it is
  already in the user's tray). `panels()[i].widgets()` enumerates instances
  without touching anything:

  ```sh
  qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
    'for (var i=0;i<panels().length;i++){
       var ws=panels()[i].widgets();
       for (var j=0;j<ws.length;j++){
         if (String(ws[j].type).indexOf("ydotool")!==-1)
           print("panel["+i+"] id="+ws[j].id+" type="+ws[j].type);
       }
     }'
  # → panel[0] id=145 type=org.tenax.ydotoolmousemover
  ```

- `containments()` is **not** part of the Plasma 6 scripting API: it throws
  `ReferenceError: containments is not defined` on 6.7.5. Use `panels()` and
  `desktops()`.
- `applet.expanded` is **not** exposed by the scripting API, so you cannot open
  the popup programmatically and cannot measure its window geometry from outside.
  Worse, `w.expanded = true` does not throw: in the `evaluateScript` context it
  silently creates an own property on the DBus wrapper, and reading it back in
  the *same* call reports `true`. It looks like it worked and nothing happened.
  Always re-read in a **fresh** `evaluateScript` call — there `w.expanded` is
  `undefined` and `w.hasOwnProperty("expanded")` is `false`, which is the real
  answer. (Verified on 6.7.5; this produced a false "I opened the popup" claim in
  one session, so check before you report it.)
- Wrapping the `pgrep` pattern in a character class (`[o]pen…`) is what keeps the
  watcher from matching itself.
- The `executable` data source runs the helper via the package path, so seeing
  `/…/plasmoids/<id>/contents/scripts/<helper> json` in the process list proves
  end-to-end wiring: QML loaded, path resolved, engine fired.
- **None of this verifies appearance.** Tooltip count, which bubble is clipped,
  hover behaviour and popup layout cannot be driven or observed from a terminal.
  For those, the honest evidence is: duplicate source removed, applet restarted
  into that file (`systemctl --user is-active plasma-plasmashell` + install
  timestamp), journal silent — then ask the user.

### Rendering the full representation without opening the popup

Prefer §4a (`plasmawindowed`): same proof, no visible change, no restart.

A desktop widget renders `fullRepresentation` inline with no user action — but
**only when there is room**: a desktop widget switches to the compact icon view
below `Plasmoid.switchWidth`/`switchHeight`, so this is not a guarantee either. If
you are testing a widget whose preferred representation is not pinned, expect to
see the content view only in a large enough slot.

```sh
# add: returns the instance id (here 153)
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
  'var d=desktops()[0]; var a=d.addWidget("org.example.widget"); print("desktop widget id="+a.id);'
sleep 5
# any QML error from creating the full representation shows up here
journalctl --user -u plasma-plasmashell --since "1 min ago" --no-pager \
  | grep -iE 'example|is not a type|TypeError|Cannot assign'
# ... and REMOVE it again: the user's desktop must look untouched
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
  'var d=desktops()[0]; var w=d.widgetById(153); if(w){w.remove(); print("removed");}'
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
  'print("widgets now="+desktops()[0].widgets().length);'   # back to 0
```

Silence in the journal after this is real evidence that the components bound,
the `required property`s were satisfied and the repeater instantiated. It still
does not prove the pixels; it does close the "was it ever loaded at all?" gap.

### plasmoidviewer, when plasma-sdk happens to be installed

`plasmoidviewer` can do two things `plasmawindowed` cannot: run a package that is
**not installed** (`-a ~/Code/plasmoid-helloworld/package`, skipping the install
step), and choose the form factor/location it loads in — which is how you test the
panel and desktop arrangements without touching the user's layout:

```sh
plasmoidviewer -a package                            # floating + planar = desktop widget
plasmoidviewer -a package -l floating -f planar      # the same thing, spelled out
plasmoidviewer -a package -l topedge -f horizontal   # panel widget
plasmoidviewer -a org.example.widget                 # an installed widget by id
QT_SCALE_FACTOR=2 plasmoidviewer -a package          # HiDPI: 96 -> 192 dpi
```

Gotchas from the tutorial: `--location=desktop` selects the *wallpaper*
containment, not desktop widgets (`floating` is what you want); a window larger
than the screen comes up maximised; and on Qt 5-era setups `console.log` needs
`QT_LOGGING_RULES="qml.debug=true"` — on 6.7.5 plasmoid `console.log` reaches the
journal without it (measured, §4a).

### Scripting API: two things worth knowing beyond widgets/panels

- `widgetById(id).showConfigurationInteface()` → the docs spell it that way (the
  typo is in the API). It opens the widget's settings dialog, which is how you get
  the real config page instantiated when you do not want to click it yourself.
- `knownWidgetTypes.includes("org.example.widget")` → is this plugin installed at
  all, without adding an instance. Handy in an install check or in a `dev.sh`.
- `panels()`, `desktops()`, `desktopsForActivity(id)`, `panelById(id)` are the
  enumeration entry points; `addWidget(name, x, y, w, h)` positions a desktop
  widget.

### A `PlasmoidItem` cannot be loaded outside plasmashell

Do not burn a round trying to `Loader { source: "…/ui/main.qml" }` from `qml6`:

```
qml: Detected a PlasmoidItem which is not the root QML item: this is not supported.
file:///…/contents/ui/main.qml:98:5: Could not create attached properties object
  'PlasmaQuick::PlasmoidAttached'
qml: loader status= 3 item= null
```

`main.qml` is only loadable by the shell (it needs a containment). Component files
(`UsageBody.qml`, `MeterRow.qml`, a config page) load fine — point a probe at them
with a `file:` URL directory import, because a bare absolute path is rejected:

```qml
import "file:/home/you/project/contents/ui" as App   // NOT "/home/you/..."
                                                 // ("not a valid import URL")
App.UsageBody { meters: [...]; smallPointSize: 8 /* … */ }
```

`required property` makes this cheap to get right: the probe fails loudly on a
value the shell forgot to pass.

## 5. Tray item: one tooltip, icon sized from the slot

Two symptoms, one widget. Hovering the tray icon opened two bubbles, the smaller
one clipped. The compact representation had

```qml
QQC2.ToolTip.visible: containsMouse
QQC2.ToolTip.text: root.toolTipSubText
QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
```

*plus* `toolTipMainText`/`toolTipSubText` on the applet. Delete the QQC2 one: the
native tooltip is the one with the title, and the QQC2 popup is parented inside the
panel window, which is what clips it. Grep for `ToolTip` in the compact
representation only — a `QQC2.ToolTip` on a button in the full representation is
correct and should stay.

The second symptom was an icon too small and off-centre, from hardcoding
`Kirigami.Units.iconSizes.smallMedium` (22 px) inside a RowLayout while the tray
hands the item the panel icon height. Size it from the slot instead and measure
both states against a synthetic slot:

```qml
Item {
    id: slot
    width: 36; height: 36          // what the tray gives when implicitWidth is 0
    property bool showText: false

    MouseArea {
        id: compactMouseArea
        anchors.fill: parent       // the tray assigns our geometry
        implicitWidth: slot.showText ? compactRow.implicitWidth : 0

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                id: iconItem
                implicitWidth: compactMouseArea.height > 0
                    ? compactMouseArea.height : Kirigami.Units.iconSizes.medium
                implicitHeight: implicitWidth
            }
            QQC2.Label { id: trayLabel; visible: slot.showText; text: "Monthly 43%" }
        }
    }
    // print iconItem.width/height and compactRow's mapped x/y, in two ticks:
    // toggling showText and reading implicitWidth in the SAME tick reports the
    // pre-toggle value, because visibility has not propagated through the
    // layout yet.
}
```

Real output:

```
icon-only : slot 36x36  | icon 36x36 | row implicitW  36 | row x 0 y 0 w 36  h 36
with text : slot 108x36 | icon 36x36 | row implicitW 108 | row x 0 y 0 w 108 h 36
```

The icon is 36 px in a 36 px slot (not 22, not off-centre), stays square, and the
row grows to fit the optional text without disturbing the icon. No binding loops.
What this cannot tell you is whether the user's tray honours the non-zero
`implicitWidth`; if the text still clips on screen, drop the text instead of
fighting the tray.

## 6. Config page without a display

The page is a plain QML file, so a `Loader` can instantiate it and you can push
values through the very `cfg_*` properties the framework uses. `i18n` is injected
by the framework at runtime, so stub it in the wrapper:

```qml
import QtQuick
import QtQuick.Controls as QQC2

QQC2.ApplicationWindow {
    visible: true
    function i18n(text, ...args) {
        return args.length ? text.replace(/%(\d+)/g, (m, n) => args[n - 1]) : text;
    }

    Loader {
        id: loader
        source: "file:///…/contents/ui/configGeneral.qml"
        onStatusChanged: if (status === Loader.Error) { console.log("LOAD_FAILED"); Qt.quit(); }
        onLoaded: {
            const p = item;
            p.cfg_pollIntervalSeconds = 300;
            p.cfg_showRolling = false;
            p.cfg_percentMode = "remaining";
            console.log("roundtrip", p.cfg_pollIntervalSeconds, p.cfg_showRolling, p.cfg_percentMode);
            Qt.quit();
        }
    }
}
```

Real output:

```
qml: loaded: FormLayout_QMLTYPE_71_QML_81(0x55d83b653f10)
qml: roundtrip 300 false remaining
qml: combo currentIndex 1 model ["used","remaining"]
```

That proves the aliases bind, that a `ComboBox` follows `cfg_percentMode` back
(index 1 for "remaining"), and that no control has a typo'd target. What it does
*not* prove is what the dialog looks like — only the user can see that.

Add two cheap assertions to the same probe, because both catch a class of bug that
is invisible until the user opens the dialog:

```js
// What AppletConfiguration.qml does when it pushes the page.
p.title = "General";
// ... then, a tick later:
console.log("fits:", p.implicitWidth <= p.width,       // else the dialog clips it
            "pads:", p.leftPadding, p.topPadding);      // 0/0 == bare FormLayout root
console.log("title settable:", "title" in p);           // false == no page heading
```

Real output before the fix (a bare `FormLayout` root with a long note):

```
PAGE type FormLayout | pads 0/0 | implicitWidth 932 vs 844 -> OVERFLOWS
```

and after (`KCM.SimpleKCM`, note wrapped and capped):

```
PAGE type SimpleKCM | title "General" | pads 6/6
OVERFLOW CHECK  page implicitWidth 0 vs available 844 -> fits
ROUNDTRIP {"trayIndicator":"dot-always","direction":"up","stepPixels":25,"intervalSeconds":3}
```

Then confirm with the real loader. plasmashell loads the page as soon as the
settings dialog is opened, and it reports every key it read:

```sh
journalctl --user -u plasma-plasmashell --since "2 min ago" --no-pager \
  | grep -i 'does not have a property called cfg_'
```

```
configGeneral.qml: Setting initial properties failed: FormLayout does not have a
property called cfg_pollIntervalSecondsDefault
… one line per key in contents/config/main.xml
```

Those lines are **benign** — the system tray's own `ConfigGeneral.qml` emits the
same ones — but the key list in them is proof the entries were parsed. If a key
you declared is missing from the list, it is not in `main.xml`; if a key appears
that you never declared, you have a stale install.

## 7. Icons

Rasterise and look at it — a 16 px "solid blob" is obvious immediately:

```sh
rsvg-convert -w 96 -h 96 contents/icons/name.svg -o /tmp/icon.png
# then view /tmp/icon.png
```

If the widget is meant to mirror a website's brand mark, fetch the official
asset (e.g. `https://example.com/favicon.svg`) and render both at the same size
to compare rather than trusting your reconstruction.

Remember the tray resolves `Plasmoid.icon` **by name from the icon theme**:
installing the SVG into `~/.local/share/icons/hicolor/scalable/apps/` (and
`kbuildsycoca6`) is what makes it appear. Files sitting only in
`contents/icons/` are findable by a relative `Qt.resolvedUrl(...)` inside your
own QML, but not by the panel.

## 8. Unit tests for the pure helpers

Anything extracted into `contents/js/<helpers>.js` is testable without a display,
which is most of the reason to extract it. `qmltestrunner` sits next to `qmllint`
in `/usr/lib/qt6/bin`, is usually not on `PATH`, and needs no plasmoid host — but
it does need a platform plugin, so force `offscreen`.

```qml
// contents/tests/tst_usage.qml
import QtQuick
import QtTest

import "../js/usage.js" as Usage        // relative to the test file

TestCase {
    name: "UsageHelpers"

    function test_usedFraction() {
        compare(Usage.usedFraction({ used: 43, limit: 100 }), 0.43);
        compare(Usage.usedFraction({ used: 5, limit: 0 }), 0, "a zero limit reads as nothing used");
        compare(Usage.usedFraction({ used: 999, limit: 100 }), 1, "clamped");
    }

    function test_durationParts() {
        // compare() on objects compares identity: stringify, or compare fields.
        compare(JSON.stringify(Usage.durationParts(((6 * 24) + 11) * 3600000)),
                JSON.stringify({ expired: false, days: 6, hours: 11, minutes: 0 }));
        compare(Usage.durationParts(NaN), null);
    }
}
```

```sh
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input contents/tests
```

```
PASS   : qmltestrunner::UsageHelpers::test_durationParts()
PASS   : qmltestrunner::UsageHelpers::test_usedFraction()
Totals: 7 passed, 0 failed, 0 skipped, 0 blacklisted, 5ms
```

Exit status is nonzero on failure and a failing `compare` prints both values. Both
paths were checked by deliberately breaking one expectation: `validate` exited 1
with `FAIL! : … Compared values are not the same`.

Two details before writing assertions: `compare()` on JS objects compares
identity, so stringify them or compare fields; and a window-less `TestCase` also
runs without `offscreen` when a platform plugin is available.

Wire this into `dev.sh validate` next to the qmllint step (with its own `test`
command), and lint `js/*.js` in the same qmllint call — it accepts plain `.js`
files and catches syntax errors there too.

## 9. Order of operations

0. Diff the source against the installed package, and check `git status` — you may
   be chasing a bug that is already fixed in the repo (possibly uncommitted) but
   not installed.
1. `./dev.sh validate` — helper syntax, metadata, `config/main.xml`, `qmllint`
   over every QML and JS file (i18n warnings filtered by source line), the
   `qmltestrunner` suite, and package structure in a throwaway root.
2. Probe the layout numerically if anything about sizing changed, probe the
   component files offscreen after a split, and probe a config page with a
   `Loader` if you added or changed settings.
3. `./dev.sh upgrade` — install + reload plasmashell.
4. Panel smoke test (section 4) — proves it loads and polls. If you refactored
   the popup, also put the widget on the desktop containment for one render
   (section 4) so `fullRepresentation` really instantiates, then remove it.
5. Ask the user to look. They are the only camera you have.
