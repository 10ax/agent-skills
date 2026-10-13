---
name: plasma-plasmoid-dev
description: Use whenever building, modifying, packaging, installing or debugging a KDE Plasma 6 widget - plasmoids, panel widgets, system tray applets, QML applets, widgets with a popup/compact representation, a settings/config page, or anything installed with kpackagetool6 into ~/.local/share/plasma/plasmoids. Also use when a plasmoid's layout, tray icon, tooltips, popup sizing, config dialog or data polling misbehaves. Covers the dev.sh install/reload loop, QML layout traps, icon resolution, KConfigXT settings pages and how to verify a widget without a display.
---

# KDE Plasma 6 Plasmoid Development

Plasma 6 applets are QML packages — no C++ needed. You edit QML, reinstall the
package, reload plasmashell, look at it. The hard parts are never the feature;
they are the packaging rules, the layout engine's opinions, icon resolution and
the fact that you cannot see the result from a terminal. This skill is mostly
about those.

## Default to making it configurable

A widget you touch should expose its user-visible choices as settings, not bake
them in. Do this as part of the feature, never "later": a widget that ships without
settings is what produces a follow-up round of "I don't like how it looks" with no
way out. The mechanism is cheap — three files and a
`Plasmoid.configuration.<name>` read (see **Settings pages** below).

When you build or modify a plasmoid, ask which of these the user could reasonably
disagree with, and expose those:

- **How often it talks to the network** — poll interval. Always.
- **What is shown** — which rows/fields, whether the meta/footer row appears.
- **How state is communicated.** If you are about to silently pick one way to show
  a state change (a coloured dot, an icon swap, nothing), expose the choice with a
  sane default instead. This is *the* most common "I don't like it but I am not
  sure what I want" complaint, and a setting turns it into a one-click fix.
- **A display mode the user could read either way** — used vs remaining, absolute
  vs relative, 12 h vs 24 h.
- **Which rows/elements exist at all** — visibility booleans per meter/field.

Do **not** expose what the theme owns (colours, spacing, sizes) or
secrets/paths/URLs — those belong to the colour scheme or the helper's environment.

Two of these choices are HIG matters, not taste: **colour may not be the only
carrier of meaning**, and a **tray icon should be opt-in and ideally only present
when there is something to report**. Both are in
`references/plasmoid-api-and-hig.md`, which also distils the upstream widget
tutorial and the KF6 porting guide (and the places where those pages are stale).

Two rules of thumb:

- **One well-named setting beats three booleans.** Prefer a single `ComboBox`
  enumerating the valid behaviours (`"dot-when-running"`, `"dot-always"`,
  `"icon-swap"`, `"none"`) over flags that combine into nonsense states.
- **Validate and clamp on read**, because the config file is user-editable.

If the user is undecided between two designs, do not guess and do not stall: ship
both behind one setting and say which default you chose.

## Start by reading the environment

Assume nothing about versions or tool locations:

```sh
plasmashell --version
pacman -Q plasma5support   # QML 'executable' data source lives here (Arch)
echo $XDG_SESSION_TYPE
ls ~/.local/share/plasma/plasmoids/   # existing local widgets are your best template
```

If the user already has a local plasmoid, **read it first** and match its
structure, `dev.sh` style and QML imports. Consistency with their own code beats
any convention you would invent.

Tooling reality checks:

- `qmllint` is often not on `PATH`. Use `/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml`.
- `qml6` / `qmlscene6` are at `/usr/bin/`. Handy for offline probes.
- `plasmawindowed` ships with **plasma-workspace** (so it is already there) and
  runs an **installed** widget in a window; for a `PlasmoidItem` it instantiates
  the full representation, so a popup body can be proven to load without the tray
  popup and without restarting the shell (measured — see
  `references/verification.md` §4a). Prefer it over `plasmoidviewer`, which needs
  `plasma-sdk` (but can run an uninstalled folder and choose form factor/location).
- Reloading plasmashell restarts the whole desktop shell. It is required for
  QML/metadata changes to take effect, but it flashes the user's screen — do it
  as part of an explicit `install`/`upgrade` command and say so, never silently.

When you need the authoritative answer for an API question, read the upstream
pages: <https://develop.kde.org/docs/plasma/widget/> (tutorial),
<https://develop.kde.org/docs/plasma/widget/porting_kf6/> (which API is current),
<https://develop.kde.org/hig/> (design). `references/plasmoid-api-and-hig.md`
distils them, including the parts the tutorial gets wrong.

## Layout: source repo vs installed package

Keep the source in a real directory (ideally under version control) and install
it with a `dev.sh`, rather than editing
`~/.local/share/plasma/plasmoids/<id>` in place. `dev.sh` commands that pay off:

`doctor` (deps + live smoke test) · `install` · `upgrade` · `reinstall` ·
`remove` · `reload` · `preview` · `status` · `validate`

`assets/dev.sh` in this skill is a working template.

- Install: `kpackagetool6 --type Plasma/Applet --install <dir>`
- Upgrade: `kpackagetool6 --type Plasma/Applet --upgrade <dir>`
- Remove: `kpackagetool6 --type Plasma/Applet --remove <id>`
- Reload: `systemctl --user restart plasma-plasmashell.service`, falling back to
  `kquitapp6 plasmashell` + `kstart plasmashell`.

Make `validate` non-destructive: install into a throwaway root with
`kpackagetool6 --packageroot "$(mktemp -d)"` so it never touches the live
package, and have it `bash -n` scripts, parse `metadata.json` with `jq`, and
check that every file the QML references actually exists.

**The installed copy can lag the source.** What the user sees is
`~/.local/share/plasma/plasmoids/<id>`, so before diagnosing a bug they report,
diff the two — a fix may already be in the repo but never installed, and
"editing" it again wastes the round:

```sh
diff -rq <source-dir>/contents ~/.local/share/plasma/plasmoids/<id>/contents
```

Trust that diff over mtimes: a source file can carry a *newer* fix while showing
an *older* timestamp than the installed copy.

A diff that differs, or a dirty `git status`, means someone may have already fixed
the bug and left the work uncommitted — possibly bundled with unrelated changes.
Read the diff before deciding: keep what is correct for the reported bug, discard
nothing blindly, and say in your report what pre-existing work you carried along.

## Package skeleton

```
<id>/
  metadata.json
  dev.sh
  contents/
    config/main.xml          # only if the widget has settings; see below
    config/config.qml
    ui/main.qml
    ui/configGeneral.qml
    ui/<Component>.qml       # optional: see "Splitting a widget" below
    js/<helpers>.js          # optional: pure logic, no i18n / no state
    tests/tst_<helpers>.qml  # optional: qmltestrunner tests for js/
    scripts/<helper>        # only if you need shell/CLI work
    icons/<name>.svg
```

`assets/metadata.json` is a template. The keys that matter:

- `KPackageStructure: "Plasma/Applet"`, `KPlugin.Id` = your reverse-DNS id.
- `X-Plasma-API-Minimum-Version: "6.0"` — **required**, and the one people forget:
  without it Plasma reads the widget as Plasma 5-only and never offers it in *Add
  Widgets*.
- `X-Plasma-MainScript: "ui/main.qml"` is **not** needed in Plasma 6 and the
  porting guide says to remove it with `X-Plasma-API`; the entry point is always
  `ui/main.qml`.
- System tray placement: `"X-Plasma-NotificationArea": true` plus
  `"X-Plasma-NotificationAreaCategory"` (`SystemServices`, `ApplicationStatus`,
  …). Without `X-Plasma-NotificationArea` the widget only lives on panels or the
  desktop, never in the tray. Add `KPlugin.EnabledByDefault: true` if it should be
  enabled in the tray without the user finding it in *Configure System Tray →
  Entries* — that toggle is the step you cannot do for them.
- `KPlugin.Category`, `Authors`, `Website`, `BugReportUrl`: list placement and the
  About page. `X-Plasma-DBusActivationService` loads the widget only while a D-Bus
  name exists, which is the tidy way to avoid a permanent tray icon for an app
  that is usually not running.

`references/plasmoid-api-and-hig.md` has the full key list (categories, Provides,
the `Plasmoid.*` properties worth knowing) and the Plasma 5 → 6 API mapping.

## Splitting a widget that has outgrown one file

A plasmoid's `ui/main.qml` starts as state + tray + popup + formatting and reaches
400+ lines quickly, at which point every change means scrolling past four
unrelated concerns. Split it, and keep the split on these lines:

- **`ui/main.qml` is the shell**: the properties that hold the latest reading, the
  poll timer, the `P5Support` engine, the tray/compact representation, the
  contextual actions, and the popup *wiring*. It owns no presentation of its own.
- **`ui/<Name>.qml` for each presentational piece** (the popup body, a repeated
  row). Same-directory files are usable by filename with no import: a
  `ui/MeterRow.qml` becomes `MeterRow { … }` in `ui/UsageBody.qml`. Give them a
  documented contract with `required property` for everything they display, so a
  missing value is a load error rather than a silently blank row.
- **`js/<helpers>.js` for logic that is arithmetic, dates or string assembly with
  no i18n and no state.** A `.pragma library` file has no `i18n()`, so keep the
  message strings in the QML side and let the library return numbers and parts
  (`{ days, hours, minutes, expired }`). That boundary is also what makes the
  logic unit-testable — see `references/verification.md` §8.
- **Right-click the components too**: a file whose root is a `PlasmoidItem`
  (`main.qml`) can only be instantiated by the shell, but `UsageBody.qml` /
  `MeterRow.qml` / a config page are plain QML and can be loaded offscreen with a
  `Loader` and measured. Do not test through the applet when you can test the
  component.

Three rules that keep the split behaviour-preserving:

- **Read settings in the QML binding expression and pass the value into the
  library.** `Plasmoid.configuration.percentMode` read in `main.qml` and passed to
  the body (`percentMode: Plasmoid.configuration.percentMode`) re-evaluates on
  change. Relying on a `.pragma library` function to reach for `Plasmoid` moves
  the read out of the binding, and the binding dependency is the thing that makes
  the UI follow the setting. (A *same-file* function used as a callback does keep
  its dependencies: `meters.filter(meterEnabled)` where `meterEnabled` reads
  `Plasmoid.configuration.showWeekly` does re-run when the setting flips — that
  one was measured, not assumed. The distinction is library file vs same-file.)
- **One source for a theme-derived value.** If a point size or a column width is
  used in two files, compute it once in the shell and pass it down
  (`smallPointSize: root.smallPointSize`) rather than repeating
  `Math.max(6, Kirigami.Theme.defaultFont.pointSize - 1)` in each. Duplicated
  constants drift the moment someone tunes one copy.
- **Rebind strings through properties, not function calls in `text:`.** A
  countdown that a shell property already formats (`refreshText`) can be passed
  as a string; a value that must follow `nowMs` can call a formatting function
  that reads it — but know which one you are doing. Both were verified working;
  mixing them randomly is what makes a "frozen" label hard to find later.

Behaviour check after a split: the maths, the colour ramp, the user-visible
strings, the `Layout` metrics and the engine contract must be untouched. Diff the
old file against the new ones and reconcile feature by feature (a reviewer agent
is good at this) before claiming the refactor is clean.

## Data in: helper script + executable engine

Do not put `curl`/`jq`/auth logic in QML. Put it in an executable under
`contents/scripts/` and call it from QML through the Plasma 5 Support engine:

```qml
import org.kde.plasma.plasma5support as P5Support

readonly property string helperPath: decodeURIComponent(
    String(Qt.resolvedUrl("../scripts/<helper>")).replace(/^file:\/\//, ""))

function refresh() {
    // Trailing comment is a cache-buster: the engine keys sources by string,
    // so an identical source would not re-run.
    executableEngine.connectSource(shellQuote(helperPath) + " json # " + Date.now());
}

P5Support.DataSource {
    id: executableEngine
    engine: "executable"
    connectedSources: []
    onNewData: (sourceName, data) => {
        disconnectSource(sourceName);
        // data.stdout / data.stderr strings, exit status under data["exit code"]
    }
}
```

Rules that keep this robust:

- The helper always exits 0 and prints **one line of JSON**, including for
  errors (`{"ok":false,"error":"network"}`). QML then only does
  `JSON.parse(stdout)`; it never deals with shell failures.
- The data map's keys are `stdout`, `stderr` and `exit code` — the last one has a
  **space**, and getting it wrong silently yields `NaN`. They are built with
  `QStringLiteral`, so an ASCII `strings` scan of
  `plasma_engine_executable.so` shows `exitCode` (a `QProcess` meta-object string,
  not a map key) while `exit code` only appears as UTF-16. Do not "correct" the
  key to `exitCode` on the strength of such a scan.
- Quote the path (`shellQuote`) — package paths contain no spaces usually, but
  the resolved URL decoding above is what actually bites.
- Never print secrets. If the helper reads a token from a local credential
  store, print only derived numbers.
- On a failed fetch keep the last good values in QML and surface the error
  separately; users hate a popup that blanks out on a transient network blip.

## Icons

`Plasmoid.icon` is resolved **by name through the icon theme**, not from the
package. Two consequences:

- Copy your SVGs into `~/.local/share/icons/hicolor/scalable/apps/` during
  `install`/`upgrade` and delete them on `remove`, otherwise the tray icon is
  blank. Run `kbuildsycoca6` after copying.
- A name ending in `-symbolic` is recoloured by the panel. That is what you want
  for a monochrome glyph, and exactly what you do *not* want for a brand mark —
  at ~16 px a symbolic brand shape collapses into a solid blob. For a logo, ship
  the coloured tile (background + glyph) and use the plain name.

Keep copies in `contents/icons/` too, for `Qt.resolvedUrl("../icons/x.svg")`
use inside your own QML. Render one with `rsvg-convert -w 96 -h 96 x.svg out.png`
and actually look at it — this catches "solid blob" icons instantly.

The HIG splits icons into **colourful** (application/MIME/places — meaningful by
themselves) and **monochrome** (actions, status — recoloured by the panel, which
is why they carry a `-symbolic` name and why a brand mark must not use one). An
action you add to the tray or the popup should use an existing action icon from
the theme before you draw your own: `view-refresh-symbolic`,
`internet-services-symbolic`, `configure`. See
<https://develop.kde.org/hig/icons/>.

## Text: i18n, and what the HIG asks of it

- **Double quotes only**: `i18n("…")`. `i18n('…')` is silently skipped by the
  string-extraction tooling, so it never gets translated.
- Plurals: `i18np("1 item", "%1 items", count)`.
- The domain for a widget is `plasma_applet_<Id>`; compiled catalogs live in
  `contents/locale/<lang>/LC_MESSAGES/plasma_applet_<Id>.mo`, built from `.po`
  files under `translate/` (xgettext/msgmerge/msgfmt, i.e. `gettext`). Test with
  `LANGUAGE="fr_CA:fr" LANG="fr_CA.UTF-8" plasmawindowed <id>`.
- `i18nd("plasma_applet_org.kde.plasma.digitalclock", "Show seconds")` reuses an
  existing translation instead of shipping a duplicate.
- HIG, for the strings themselves: errors must say what happened *and* what to do
  about it; never a bare "error", never a silent failure; blame the third party
  when it is the third party's fault. Avoid negative language
  (kill→close, abort→exit, fatal→critical), and put the distinctive part first
  ("Monthly 43%", not "43% monthly").

`references/plasmoid-api-and-hig.md` has the full extraction workflow and the
rest of the HIG checklist (colour semantics, tooltip rules, keyboard/screen-reader
tests, font size 14, animations off).

## Settings pages (KConfigXT)

A widget with no `contents/config/` has a settings dialog containing only
*Keyboard Shortcuts* and *About* — that is the symptom to recognise. Settings are
three files:

```
contents/config/main.xml        # the entries, with <default> values
contents/config/config.qml      # registers the page(s)
contents/ui/configGeneral.qml   # the controls
```

**The page root must be a Page, and specifically `KCM.SimpleKCM`.** A bare
`Kirigami.FormLayout` root has no page padding (the form sits flush against the
top-left) and no `title` property, so the page heading never appears. This is what
the dialog does with your page — see
`/usr/share/plasma/shells/org.kde.plasma.desktop/contents/configuration/AppletConfiguration.qml`:

```js
const props = { "title": item.name };          // the ConfigCategory name
config.keys().forEach(key => { props["cfg_" + key] = config[key]; });
pushReplace(Qt.resolvedUrl(item.source), props);   // into a Kirigami.PageRow
```

The heading in the dialog is that PageRow's global toolbar rendering the page's
`title`. So:

```qml
KCM.SimpleKCM {                 // import org.kde.kcmutils as KCM
    id: page
    property alias cfg_showRolling: rollingCheck.checked
    Kirigami.FormLayout { ... }
}
```

`SimpleKCM` is a `Kirigami.ScrollablePage`: 6 px padding on all sides, scrolling,
the `title` property, and it is what Plasma's own pages use (`systemmonitor`,
`desktopcontainment`). There is no need to draw the heading yourself — and doing
so gives you two of them.

The four KCM roots and when each is right (from the porting guide): `SimpleKCM`
for arbitrary content — the default choice; `AbstractKCM` when you need to control
where the `ScrollView` goes yourself; `ScrollViewKCM` when the page is a central
`ListView` (with `header`/`footer` controls); `GridViewKCM` for a central
`GridView`.

Two settings affordances worth knowing:

- `Plasmoid.configuration.<name>Default` reads the `<default>` you declared (KF ≥
  5.78), so "is this different from stock?" and a reset button are cheap.
- `Plasmoid.configurationRequired = true` puts a Configure button on top of the
  representation, for a widget that genuinely cannot work until the user sets
  something. Prefer this over a widget that silently shows nothing.
- If you do expose a colour, store it as an **empty `String` by default** and fall
  back to the theme in QML (`color: Plasmoid.configuration.labelColor ||
  Kirigami.Theme.textColor`). The `Color` type has no "unset" state and casts an
  empty default to black, which then stops following the colour scheme.

Every entry in `main.xml` is readable anywhere in the widget as
`Plasmoid.configuration.<name>`, and the page receives it as a `cfg_<name>`
property. Declaring that property is not optional: the dialog's `saveConfig()`
copies back only what `"cfg_" + key in pageStack.currentItem` matches, and
`isConfigurationChanged()` tests it with `hasOwnProperty`.

```qml
    property alias cfg_showRolling: rollingCheck.checked   // alias => Apply/Discard works
    QQC2.CheckBox { id: rollingCheck; text: i18n("Rolling") }
```

Use plain `QtQuick.Controls` controls and `Kirigami.FormLayout`, **not**
`PlasmaComponents.*`, which are styled for the panel.

Keep the setting list small — poll interval, what to show, how state is
communicated, a display mode; never paths, tokens or API URLs.

`references/settings.md` has the full walkthrough: `main.xml`, `config.qml`, a
complete SpinBox/CheckBox/ComboBox page, how to consume the values in `main.qml`,
and the `dev.sh validate` checks for it.

## QML layout traps that will bite you

**Un-elided text starves `Layout.fillWidth` siblings.** A label whose text is
wider than the space reports that width as its implicit size; a column with no
`Layout.maximumWidth` will happily eat every free pixel and squeeze a progress
bar down to nothing. Cap such columns (`Layout.maximumWidth`) and give the
flexible item a `Layout.minimumWidth`. Symptom to recognise: a bar renders as a
dot at the far end of the row.

**A bar's minimum-width floor must not apply at zero.** Floors exist so a small
non-zero share does not collapse into an invisible line or read as a slider knob,
but applied unconditionally they draw a sliver at 0% — which reads as "a little
used" when it means "nothing used". Gate it:

```qml
// fill: 0 stays 0; a tiny non-zero share is floored to the radius
width: share <= 0 ? 0 : Math.max(radius, trackWidth * share)
```

Put the arithmetic in a pure helper next to the other derivations rather than
inline, so it can be unit-tested (`fillWidth(0, 400, 4) === 0`); the same helper
should clamp the floor to the track width and guard NaN. Symptom to recognise: a
coloured nub in an otherwise empty bar, at 0%.

**`PlasmaExtras.Representation` is a Page; its padding and the popup height are
independent.** If you set explicit `topPadding`/`bottomPadding`, the popup can
still be sized to the content only and clip the last row. Bind the height hint:

```qml
contentItem: ColumnLayout { id: body; ... }
Layout.minimumHeight: body.implicitHeight + topPadding + bottomPadding
```

`PlasmaQuick::AppletPopup::updateMinSize` reads `Layout.minimumHeight`, so this
is the lever that actually fixes clipping.

**Even insets:** to guarantee the same padding on all edges regardless of the
theme's dialog background metrics, set `leftPadding`/`rightPadding`/`topPadding`/
`bottomPadding` explicitly rather than inheriting them. `Representation.qml`
binds those four to `BackgroundMetrics.getMargin()`; overriding them with
constants is fine, and the inset you *see* is your padding plus the theme's frame
margin, so 8 px of padding does not look like 8 px.

**Never put a `QQC2.ToolTip` on the compact representation.** The applet already
has a native tooltip driven by `toolTipMainText`/`toolTipSubText`, so hovering
the tray icon opens *two* bubbles, and the QQC2 one is clipped because it is
parented inside the panel window. Symptom: two tooltips, one truncated, usually
the smaller one. Keep the native pair and delete the QQC2 one (and the
`QtQuick.Controls` import if it was the only use). A `QQC2.ToolTip` on a button
*inside* the full representation is fine — different context, no duplicate.

**Size the compact representation from the slot, not from a constant.** The tray
hands the item the panel's icon height; a hardcoded
`Kirigami.Units.iconSizes.smallMedium` (22 px) renders visibly small and, inside
a RowLayout, off-centre. Do:

```qml
compactRepresentation: MouseArea {
    id: compactMouseArea

    // 0 width when there is no extra content: the tray keeps giving us its
    // square slot. Widen only for real content (e.g. an optional percentage).
    implicitWidth: Plasmoid.configuration.showTrayText ? compactRow.implicitWidth : 0
    anchors.fill: parent          // the tray assigns our geometry

    RowLayout {
        id: compactRow
        anchors.centerIn: parent

        Kirigami.Icon {
            implicitWidth: compactMouseArea.height > 0
                ? compactMouseArea.height : Kirigami.Units.iconSizes.medium
            implicitHeight: implicitWidth
        }
        // ... optional Label, visible only when the setting asks for it
    }
}
```

Measure it against a synthetic slot as in `references/verification.md`: a 36×36
slot must give a 36×36 icon and a centred row.

**`Kirigami.Theme.smallFont` may not be smaller than the default font.** On some
themes both are the same size (measured: 9 pt / 12 px for both), so
`font: Kirigami.Theme.smallFont` gives you no hierarchy at all and secondary
lines look as important as primary ones. Use an explicit
`font.pointSize: Kirigami.Theme.defaultFont.pointSize - 1` and verify with a units
probe before trusting any `Kirigami.Units.*` value.

**Grouping needs an explicit ratio.** Body `spacing` applies between *and* inside
your rows, so a label and its sub-line end up as far apart as two unrelated
meters, and the popup reads as one undifferentiated block of text. Make the gap
between groups clearly larger than the gap inside one (e.g. `smallSpacing` inside,
`Math.round(gridUnit * 0.75)` between). Put a `Kirigami.Separator` before a footer
row so it does not read as one more data row.

**A `FormLayout` gives its first item no top margin and no page padding of its
own.** That is by design (`Layout.topMargin: index === 0 ? 0 : largeSpacing * 2` in
`layouts/FormLayout.qml`), so a page whose root is the form looks crammed against
the top of the dialog. Wrap it in `KCM.SimpleKCM`.

**A long `Label` inside a `FormLayout` sets the page's implicit width.**
`wrapMode: Text.WordWrap` does not help on its own — with no width constraint the
label reports its *unwrapped* one-line width as `implicitWidth`, the whole page
grows past the dialog and the text is clipped. Measured: a 90-character note gave
a page `implicitWidth` of 932 px in an 844 px dialog. Constrain it
(`Layout.maximumWidth`) or keep it short. Same trap as the progress bar earlier,
one level up.

**`Kirigami.FormData.isSection: true` renders the item's label as a right-aligned
level-3 heading**, with extra spacing above instead of a separator line
(`FormLayout.qml`: `type: Primary`, `level: 3`, `columnSpan: all`). Use it for group
headings only — not for the page title, and not for a help paragraph, which will
end up right-aligned and mis-parented.

**Do not centre a progress bar between two text lines.** If the label and its
sub-line form a two-line column and the bar sits next to it, the bar is centred on
the *pair* and lines up with neither line. Put the label, bar and value on one
line and let the sub-line span underneath it; the bar then aligns with its own
label for free.

**A fixed-size host spreads the slack between your rows.** The system tray's
popup is a fixed window (432×432 on this setup) while a widget body often needs
far less (measured: 218 px). Qt Quick's layouts put the leftover height into the
**gaps between children** — in that host a 13 px group gap and the 8 px inner
spacings both became 93 px, so the header floated away from the meter list and the
footer drifted into the middle. The same widget in a panel/desktop slot that sizes
itself to the content looks correct, which is what makes this confusing to report:
"the tray popup has so much spacing".

```qml
ColumnLayout {              // the popup body
    RowLayout { … }         // header
    ColumnLayout { … }      // the rows
    // … error line, separator, footer …
    Item { Layout.fillHeight: true }   // all the slack lands here
}
```

Measured after the fix in the same 432 px host: the header keeps its 8 px gap to
the list, the list lays out at its natural height, the spacer holds 214 px, and the
separator/footer sit at the bottom. Costs one `spacing` unit of bottom padding when
the host *is* content-sized (implicitHeight 210 → 218). Also state the height
preference, not just the minimum, so a host that honours it hugs the content:

```qml
Layout.minimumHeight: body.implicitHeight + topPadding + bottomPadding   // no clipping
Layout.preferredHeight: body.implicitHeight + topPadding + bottomPadding // no slack
```

**Live counters:** keep the poll interval in one property, drive one timer from
it, and add a separate 1 s timer that only updates a `nowMs` property. Derive
every countdown ("Resets in 3h 57m", "Refreshing in 12s") from `nowMs` so they
all tick together and none of them trigger a fetch.

Across a `Repeater`, delegates *do* participate in the parent layout, and with
`pragma ComponentBehavior: Bound` each delegate should declare
`required property var modelData`.

## Verifying without a display

You usually cannot see the popup. You can still measure everything, and — better
than any offscreen probe — `plasmawindowed <your.plugin.id>` runs the **installed**
widget in a real window inside real Plasma, which instantiates
`fullRepresentation` for you (measured: the popup body and every repeater row
loaded, `console.log` from the QML landed in the user journal). No tray popup, no
plasmashell restart, no visible change to the user's desktop. It is preinstalled
with plasma-workspace, unlike `plasmoidviewer` (plasma-sdk). Start there; the
details are in `references/verification.md` §4.

**Measure layout numerically.** Replicate the suspect subtree in a standalone
QML with a plain `Item` root (layouts compute without a window) and print real
geometry:

```sh
QT_QPA_PLATFORM=offscreen QT_FORCE_STDERR_LOGGING=1 timeout 20 qml6 probe.qml
```

`console.log` only reaches your terminal with `QT_FORCE_STDERR_LOGGING=1`.
Print `width`, `implicitWidth`, `height`, `implicitHeight` of the layout chain —
that is how you discover that a label is 263 px wide and the bar is 1 px.
`assets/probe-layout.qml` is a starting point. Instead of guessing what
`Kirigami.Units` means on this machine, print it first:

```qml
import org.kde.kirigami as Kirigami
Item {
    Component.onCompleted: {
        console.log("gridUnit", Kirigami.Units.gridUnit,
                    "smallSpacing", Kirigami.Units.smallSpacing,
                    "largeSpacing", Kirigami.Units.largeSpacing);
        console.log("default font", Kirigami.Theme.defaultFont.pointSize,
                    "small font", Kirigami.Theme.smallFont.pointSize);
        Qt.quit();
    }
}
```

On Breeze with the default font that is `gridUnit 18`, `smallSpacing 4`,
`largeSpacing 8`, and both fonts 9 pt — the last one is why
`font: Kirigami.Theme.smallFont` buys you nothing. Theme colours come out as
`#000000` under the offscreen platform, so read units and font sizes there, not
colours.

Then measure the subtree you actually suspect. `grabToImage` does *not* fire
reliably under the offscreen platform; prefer numbers, and use
`rsvg-convert`/`kreadconfig`-style tools for anything image-shaped.

**Prove the real applet loads.** Add it to a panel through the shell's scripting
API, confirm it runs, then remove it — leaving the user's panel untouched:

```sh
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
  'var p=panels()[0]; var a=p.addWidget("<id>"); print(a.id);'
# ... then: p.widgetById(<id>).remove()
```

If adding/removing is not acceptable (or the widget is already in the user's
tray), use the read-only form instead — it answers "is my instance loaded, and
how many?" without touching anything:

```sh
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
  'for (var i=0;i<panels().length;i++){
     var ws=panels()[i].widgets();
     for (var j=0;j<ws.length;j++){
       if (String(ws[j].type).indexOf("<id-fragment>")!==-1)
         print("panel["+i+"] id="+ws[j].id+" type="+ws[j].type);
     }
   }'
```

`containments()` does **not** exist in the Plasma 6 scripting API, and does not in
6.7.5 either — it is a common false lead from older docs. Use `panels()` and
`desktops()`.

Note what an applet being loaded does *not* prove: you cannot count tooltip
bubbles, see which one is clipped, or drive a hover from a terminal. For
tooltip/tray-appearance bugs the terminal evidence is only (a) the duplicate
source is gone, (b) the applet restarted into that file, (c) no QML errors in the
journal — say that plainly and have the user confirm the visuals.

Listen for the applet actually doing work right after it is created:

```sh
pgrep -af '[h]elper json'    # bracket stops the watcher matching itself
```

A shell `pgrep` pattern without the bracket trick will match its own command
line and give you a false positive — that is not evidence.

**Read the shell's log** for QML errors. Plasmoid errors surface here and
nowhere else:

```sh
journalctl --user -u plasma-plasmashell --since "1 min ago" --no-pager
```

`qmllint` reports every `i18n("…")` as "Unqualified access" — that is a false
positive in plasmoids, where `i18n` is injected at runtime. Filter those lines so
real warnings are visible, but filter *by source line*, not by warning class, or
you also hide a typo'd id: see the `qmllint` recipe above and
`references/verification.md` §1.

That journal is shared with every other widget and shell component, so grep for
your own **package id** before concluding anything — a bare filename is a bad
discriminator, because `main.qml` belongs to dozens of applets and a generic
pattern like `is not a type` will match the brightness applet:

```sh
journalctl --user -u plasma-plasmashell --since "2 min ago" --no-pager \
  | grep -iE 'plasmoids/org\.example\.mine|ReferenceError|binding loop'
```

Lines mentioning other applets (the brightness applet's
`PopupDialog.qml: TypeError: Value is null…` is a perennial one) are not yours.
Test the filter by checking that it stays silent when your widget has no problem.

`qmllint` noise is not just `Unqualified access`: it also prints
`Info: Did you mean "icon"?` for every `i18n(…)`. Do **not** filter the whole
`Unqualified access` class away — a typo in a property or id name is reported
with exactly that warning, which is the most likely mistake in a refactor that
introduces `required property`s. Filter by the warning's own source line instead:
drop it only when that line is an `i18n` call.

```sh
/usr/lib/qt6/bin/qmllint -I /usr/lib/qt6/qml contents/ui/*.qml contents/js/*.js 2>&1 \
  | awk '/^(Warning|Error):/ {
           warning = $0
           getline source
           if (warning ~ /Unqualified access \[unqualified\]$/ && source ~ /i18n[cndp]*\(/) next
           print warning
         }'
# (no output) == clean
```

To check your filter is not a no-op, prove it still fails on a real typo: add
`property int broken: bodyy` (a misspelled id) to a component, run the pipeline,
and confirm the `Unqualified access` line survives. Then remove it.

A file rewritten back to its original content mid-edit is not QML: an editor or
IDE holding a stale buffer can clobber your writes. Diff (`git diff --stat`)
right after editing and again a few seconds later before you blame the code.

## Symptom → cause

| Symptom | Likely cause |
|---|---|
| Widget never appears in the tray | `X-Plasma-NotificationArea` missing in metadata |
| Widget never appears in *Add Widgets* at all | `X-Plasma-API-Minimum-Version: "6.0"` missing; Plasma reads it as a Plasma 5 widget and hides it |
| The user has to enable the tray widget by hand | no `KPlugin.EnabledByDefault: true` |
| A tray icon sits there for an app that is usually not running | consider `X-Plasma-DBusActivationService` so the widget only loads with the service |
| A colour setting stops following the colour scheme once set | `Color` config type; store an empty `String` default and fall back to a `Kirigami.Theme` colour |
| The colour ramp is the only thing telling the user something is wrong | HIG: pair it with text/shape; colour never carries meaning alone |
| Tray icon blank | icons never copied to the icon theme dir |
| Tray icon is a solid blob | `-symbolic` name used for a brand mark at 16 px |
| **Hover shows two tooltips, one clipped** | a `QQC2.ToolTip` on the compact representation duplicating the native `toolTipMainText`/`toolTipSubText` |
| **Tray icon too small and off-centre** | a hardcoded icon size (e.g. `iconSizes.smallMedium`) instead of sizing from the slot the tray gives you |
| **Settings dialog only has Keyboard Shortcuts + About** | no `contents/config/` in the package |
| **No page heading/title in the settings dialog** | page root is not a Page (e.g. a bare `Kirigami.FormLayout`), so `title` cannot be set; use `KCM.SimpleKCM` |
| **Settings page crammed against the top, or long text clipped** | bare `FormLayout` root (no padding) and/or a wide `Label` inflating the page's `implicitWidth` |
| **"I don't like it, but I'm not sure what I'd want instead"** | a design choice was baked in; expose it as a setting (see **Default to making it configurable**) |
| Progress bar render as a dot | un-capped text column eating the `fillWidth` space |
| A bar shows colour at 0% | the fill's minimum-width floor applied unconditionally; gate it on `share > 0` |
| Progress bar sits between its two text lines | a `ColumnLayout` of label + sub-line next to the bar; put the bar on the label's line |
| Popup reads as one undifferentiated block | body `spacing` used for both the intra-row and the inter-row gap |
| The same widget looks much airier in the tray than on the panel | the tray's popup has a fixed size and Qt Quick pours the slack into the gaps between rows; finish the body with `Item { Layout.fillHeight: true }` |
| Secondary text as large as primary text | `Kirigami.Theme.smallFont` is the same size as the default font on this theme |
| Popup clips its last row | explicit padding without a matching `Layout.minimumHeight` |
| Popup has a band of empty space | a forced `Layout.minimumHeight` larger than the content |
| Countdown frozen between polls | no 1 s ticker; `nowMs` only updated on fetch |
| Helper never runs | wrong `helperPath` (URL not decoded) or missing executable bit |
| Config change appears only after a poll | binding not re-evaluated; read config through a `property`/function so the dependency is captured |
| A setting or meter list stopped updating after a refactor | the read moved out of the binding into a `js/` library function; read the setting in the QML binding expression and pass the value in |
| A typo'd property/id ships despite a clean lint | the lint filter drops the whole `Unqualified access` class, which is the warning that class produces; filter by source line instead |
| "I opened the popup from the terminal" | `applet.expanded` is not in the scripting API; assigning it silently sets a JS property on the DBus wrapper. Put the widget on the desktop containment for a real `fullRepresentation` render |

## Working with the user

They can see what you cannot. Ship a change, ask them to reopen the popup and
say what is off — "the padding looks right but the text is clipped" pins a bug
instantly. Tune padding and sizing in small explicit numbers and tell them which
property to nudge; do not guess twice in a row without a screenshot.

When they say they dislike *how* something looks and are unsure what to replace it
with, stop guessing and make it a setting (see **Default to making it
configurable**). State the default you picked so they can flip it in one click.

See `references/verification.md` for the full probe and smoke-test transcripts, and
`references/settings.md` for the settings/configuration walkthrough.
