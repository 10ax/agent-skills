# Settings pages (KConfigXT)

Adding user-configurable settings to a plasmoid. A widget with no
`contents/config/` has a settings dialog containing only *Keyboard Shortcuts* and
*About* — that is the symptom to recognise from the user's side.

Three files:

```
contents/config/main.xml        # the entries, with <default> values
contents/config/config.qml      # registers the page(s)
contents/ui/configGeneral.qml   # the controls
```

## contents/config/main.xml

`<group>` is a storage namespace, not a page binding: **every** entry is readable
anywhere as `Plasmoid.configuration.<name>`, whatever group it is in. The
page↔group link is convention only (a group named `General` plus a
`configGeneral.qml`, wired by `source:` in `config.qml`). Typed entries:
`Int`, `Bool`, `String`, `Double`, `Path`, `PathList`, `StringList`, `Color`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://www.kde.org/standards/kcfg/1.0
      http://www.kde.org/standards/kcfg/1.0/kcfg.xsd">
  <kcfgfile name=""/>

  <group name="General">
    <entry name="pollIntervalSeconds" type="Int">
      <label>Seconds between usage requests to the OpenCode console.</label>
      <default>60</default>
    </entry>
    <entry name="showRolling" type="Bool">
      <label>Show the rolling (5 hour) meter.</label>
      <default>true</default>
    </entry>
    <entry name="percentMode" type="String">
      <label>Whether the meters report the share used or the share remaining: "used" or "remaining".</label>
      <default>used</default>
    </entry>
  </group>
</kcfg>
```

Every entry is readable from anywhere in the widget (not just the config page) as
`Plasmoid.configuration.<name>`. Values are stored in
`~/.config/plasma-org.kde.plasma.desktop-appletsrc`.

Which settings are worth exposing:

- **Poll interval.** The only one that costs anything when wrong.
- **What to show** — per-row/per-element visibility booleans.
- **Whether to show the footer/meta row.**
- **A display mode** — e.g. "share used" vs "share remaining".

What not to expose: filesystem paths, tokens, API URLs (a text field invites
typos, and the helper's environment variables cover those), and anything the
theme owns (colours, spacing, bar thickness). If you do expose a colour, store it
as an empty `String` and fall back to a `Kirigami.Theme` colour in QML — the
`Color` type has no unset state and turns an empty default into black, which stops
following the colour scheme.

Two related affordances: `Plasmoid.configuration.<name>Default` (KF ≥ 5.78) reads
the `<default>` you declared, so an "is this changed?" indicator or a reset button
is cheap; and `Plasmoid.configurationRequired = true` shows a Configure button on
the widget for a setting it genuinely cannot work without. More in
`references/plasmoid-api-and-hig.md`.

## contents/config/config.qml

`source` is relative to `contents/ui/`. System applets import
`org.kde.plasma.configuration` unqualified — match them:

```qml
import QtQuick

import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
}
```

`ConfigCategory` also takes `visible`, so you can show a page conditionally.

## contents/ui/configGeneral.qml

The root must be `KCM.SimpleKCM` (`import org.kde.kcmutils as KCM`), not a bare
`Kirigami.FormLayout`. The dialog pushes each page into a `Kirigami.PageRow` with
initial properties `{"title": <ConfigCategory name>, "cfg_<key>": <value>, …}`
(see `AppletConfiguration.qml` in the plasma-desktop shell package) and the
PageRow's global toolbar renders that `title` as the page heading. A
`FormLayout` root has no `title` property and no page padding, so you get neither
heading nor margins — just the form jammed against the top-left.

`SimpleKCM` is a `Kirigami.ScrollablePage`: 6 px padding, scrolling, `title`, and
it is what `systemmonitor` and `desktopcontainment` use. Let it draw the heading;
adding your own gives you two.

The porting guide names four KCM roots: `SimpleKCM` (arbitrary content — the
default), `AbstractKCM` (no built-in `ScrollView`; use when you want to place and
size it yourself), `ScrollViewKCM` (page is a central `ListView`, plus
`header`/`footer` controls), `GridViewKCM` (central `GridView`).

Note the upstream `docs/plasma/widget/configuration/` page still shows a bare
`Kirigami.FormLayout` root — it predates the KCM requirement. The dialog needs a
`Page`, so treat the porting guide (and the observed behaviour above) as current.

Inside it, use `Kirigami.FormLayout` with `Kirigami.FormData.label`, and the
**plain `QtQuick.Controls`** widgets — `PlasmaComponents.*` are styled for the
panel and are explicitly not for config pages.

The framework copies every entry onto the page root as a `cfg_<name>` property, so
alias it. Declaring the property is what wires up **Apply/Discard** — the dialog's
`saveConfig()` only copies back keys where `"cfg_" + key in currentItem`, and
`isConfigurationChanged()` tests `hasOwnProperty`:

```qml
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: page

    property alias cfg_pollIntervalSeconds: intervalSpin.value
    property alias cfg_showRolling: rollingCheck.checked
    // Not an alias: a ComboBox maps an index to a string value.
    property string cfg_percentMode

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: i18n("Refresh every:")
            from: 15
            to: 1800
            stepSize: 15
            editable: true
            textFromValue: (value) => i18n("%1 s", value)
            valueFromText: (text) => Number.parseInt(text, 10) || 60
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Meters")
        }

        QQC2.CheckBox { id: rollingCheck; text: i18n("Rolling (5 hour)") }

        QQC2.ComboBox {
            id: percentCombo
            Kirigami.FormData.label: i18n("Show:")
            textRole: "text"
            model: [
                { value: "used", text: i18n("Percentage used") },
                { value: "remaining", text: i18n("Percentage remaining") }
            ]
            // Bind currentIndex rather than calling indexOfValue() in
            // Component.onCompleted: cfg_<name> may not be populated yet at that
            // point and the combo would come up blank.
            currentIndex: page.cfg_percentMode === "remaining" ? 1 : 0
            onActivated: page.cfg_percentMode = model[currentIndex].value
        }

        QQC2.Label {
            // A plain row, NOT a section: FormLayout renders section labels as
            // right-aligned level-3 headings, which is wrong for a help line.
            Layout.fillWidth: true
            text: i18n("Changing these restarts the meter if it is running.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            // Keep the unwrapped one-line width from widening the whole page.
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        }
    }
}
```

Reading `Plasmoid.configuration.<name>` directly inside a config page applies the
change immediately and skips the dialog's buttons. Sometimes wanted, usually not —
prefer the `cfg_` properties.

A page can also expose `saveConfig()` (called before the dialog writes),
`configurationChanged` and `unsavedChanges`, which the dialog honours (see the
comments in `AppletConfiguration.qml`).

## Consuming the settings in main.qml

`Plasmoid.configuration.<name>` is a live binding source, so read it in a
`property` or a function the binding calls and the widget reacts when the user
presses Apply:

```qml
readonly property int pollIntervalMs: Math.max(15, Math.min(1800,
    Number(Plasmoid.configuration.pollIntervalSeconds) || 60)) * 1000

function meterEnabled(meter) {
    switch (meter && meter.key) {
    case "fiveHour": return Plasmoid.configuration.showRolling;
    case "week":     return Plasmoid.configuration.showWeekly;
    default:         return true;   // unknown key: never hide data
    }
}
readonly property var visibleMeters: meters.filter(meterEnabled)
```

Match rows on a **stable key**, not on a display label, and keep unknown keys
visible — a reworded label in an API response should not silently unhide or hide a
row. Clamp numeric settings on read too: the config file is user-editable.

If the user can hide everything, handle the empty case explicitly (a placeholder,
not a blank box).

### Settings that only take effect when something (re)starts

Some settings are consumed at start-up: a helper that launches a systemd unit, a
loop that reads its interval once, a process that is exec'd with the value baked
in. A user changing one while it runs expects it to apply, so restart it on change —
and guard the *initial* binding evaluation, or the widget re-creates a healthy
process every time plasmashell loads it:

```qml
readonly property string helperOptions: "--step " + root.stepPixels
    + " --interval " + root.intervalSeconds
    + " --direction " + root.direction

property bool ready: false          // flipped in Component.onCompleted

onHelperOptionsChanged: {
    if (root.ready && root.moverActive) {
        root.runHelper("restart");
    }
}

Component.onCompleted: {
    root.ready = true;
    root.refreshStatus();
}
```

Give the helper a `restart` verb if it does not have one; stopping and starting is
usually not equivalent to re-running it (a unit keeps its environment).

## Warnings: one is noise, one is a real signal

```
configGeneral.qml: Setting initial properties failed: FormLayout does not have a
property called cfg_pollIntervalSecondsDefault
configGeneral.qml: QML FormLayout: Created graphical object was not placed in the
graphics scene.
```

The `cfg_<name>Default` lines and the "not placed in the graphics scene" one are
noise — Plasma's own applets emit them too (the system tray's `ConfigGeneral.qml`
included, with `cfg_shownItemsDefault`, `cfg_pinDefault`, …). Ignore those.

But watch the same message for **`title`**:

```
Setting initial properties failed: FormLayout does not have a property called title
```

That one is not noise. `title` is the category name the dialog sets so the page
heading can be rendered, and it fails precisely because the root is not a Page.
It is the fingerprint of the "no heading" bug — fix the root (`KCM.SimpleKCM`),
do not filter it away.

The `cfg_<name>` lines are also *evidence*: the loader logs one line per key it read
out of your `main.xml`. Seeing all your keys with none missing means the entries
parsed; a key you declared but do not see is not in `main.xml`, and a key you see
but never declared means a stale install.

## Validation

Add to `dev.sh validate`:

```sh
if [ -e "$script_dir/contents/config/main.xml" ]; then
    xmllint --noout "$script_dir/contents/config/main.xml" || failed=1
    # every page named by config.qml must exist, or the dialog comes up empty
    for page in $(sed -n 's/.*source:[[:space:]]*"\([^"]*\)".*/\1/p' \
                  "$script_dir/contents/config/config.qml"); do
        [ -e "$script_dir/contents/ui/$page" ] || { printf 'missing page %s\n' "$page"; failed=1; }
    done
fi
```

A page that does not resolve shows up as an empty or missing settings tab, which is
hard to diagnose from outside — hence the check.

See `references/verification.md` §6 for loading the page offscreen with a stubbed
`i18n()` and pushing values through the `cfg_*` properties.
