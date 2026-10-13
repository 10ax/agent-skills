# Plasma 6 plasmoid API, metadata and HIG — distilled from the KDE docs

Sources, in the order I would read them:

- <https://develop.kde.org/docs/plasma/widget/> — the widget tutorial (setup,
  QML, API, properties, configuration, i18n, examples, testing).
- <https://develop.kde.org/docs/plasma/widget/porting_kf6/> — KF5→KF6 porting
  guide; the fastest way to learn which API is current.
- <https://develop.kde.org/docs/plasma/scripting/api/> — the *scripting* API
  (`panels()`, `widgetById()`, `addWidget()`), which is a different surface.
- <https://develop.kde.org/hig/> — the Human Interface Guidelines.
- <https://api.kde.org/plasma-index.html> — generated API reference.

Everything below is from those pages unless marked **(measured)**, which means it
was checked on the machine while writing this skill.

## metadata.json

The upstream template, plus the keys that decide whether your widget shows up at
all:

```json
{
    "KPlugin": {
        "Authors": [{ "Name": "…", "Email": "…" }],
        "Category": "System Information",
        "Description": "…",              // one line; the default tooltip subtext
        "Icon": "battery",
        "Id": "com.example.helloworld",  // the package namespace = folder name
        "Name": "Hello World",           // shown in "Add Widgets"
        "Version": "1",
        "Website": "https://…",
        "BugReportUrl": "https://…"
    },
    "X-Plasma-API-Minimum-Version": "6.0",
    "KPackageStructure": "Plasma/Applet"
}
```

- **`X-Plasma-API-Minimum-Version: "6.0"` is the key that makes a widget Plasma 6.**
  Without it Plasma assumes the widget is Plasma 5 and never offers it.
- **`X-Plasma-MainScript` / `X-Plasma-API` should be dropped in Plasma 6.** The
  entry point is always `ui/main.qml` now, and the porting guide says to remove
  both keys (they are tolerated, not required — older tutorials still show them).
- `KPlugin.EnabledByDefault: true` is what makes a **notification-area** widget
  enabled in the system tray by default. Without it the user must enable it in
  *Configure System Tray → Entries*, which is the step you cannot do for them.
- `X-Plasma-NotificationArea` + `X-Plasma-NotificationAreaCategory`
  (`ApplicationStatus`, `Hardware`, `SystemServices`) put the widget in the tray.
- `X-Plasma-DBusActivationService` loads/unloads the widget automatically around a
  D-Bus name (wildcards allowed): set it to the service your widget tracks and
  the tray only holds it while the app is running. Good for "usage of a running
  app" widgets, and it is the tidy alternative to polling for something that is
  simply not there.
- `X-Plasma-Provides` declares alternative-functionality groups
  (`org.kde.plasma.time`, `org.kde.plasma.powermanagement`, …) so the widget can
  be offered in place of another one. Optional, and only meaningful for a handful
  of functions.
- `Category` filters the widget list; the valid names are on
  <https://develop.kde.org/docs/plasma/widget/properties/#category>
  (`System Information`, `Online Services`, `Utilities`, `Date and Time`, …).

## Representation: which view gets shown

A `PlasmoidItem` has `compactRepresentation` and `fullRepresentation`. If you set
neither, **the root item itself is the full representation**.

- In a panel, the widget shows the compact view and the full view opens in a popup
  when `Plasmoid.expanded` is true (that is what the default compact
  representation's `MouseArea` toggles; if you write your own compact
  representation, you must toggle `expanded` yourself).
- On the desktop, the widget can switch from the icon view to the content view
  when there is room, and `Plasmoid.switchWidth` / `switchHeight` set that
  threshold. **A desktop widget is therefore not guaranteed to show
  `fullRepresentation`** — if you need that for a test, force it with
  `Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation`.
- `Plasmoid.preferredRepresentation` pins one of the two (`Plasmoid.fullRepresentation`
  or `Plasmoid.compactRepresentation`) and is the supported way to make a widget
  show content directly on the desktop/panel instead of an icon.
- `width`/`height` set the default size of a **desktop** widget; desktop widgets
  ignore `Layout.preferredWidth` for their initial size. In a panel,
  `Layout.preferredWidth` also influences the popup size — but the docs say the
  **system tray gives its popups a fixed size**, so do not count on your own
  preference there; size the popup from its content and check it in the tray
  **(measured: `Layout.minimumHeight` on the full representation is what keeps the
  tray popup from clipping the last row — see `verification.md` §3)**.
- `plasmoid.location` / `plasmoid.formFactor` tell you where you are (panel edge,
  planar desktop, in a containment) when the layout has to differ.
- `Plasmoid.hideOnWindowDeactivate: false` pins the popup open (the digital
  clock's "pin" uses this).

## Plasmoid API worth knowing (beyond what the tutorial shows)

| Property / method | Use |
|---|---|
| `Plasmoid.configuration.<name>` | the value; readable anywhere in the widget, whatever group it lives in |
| `Plasmoid.configuration.<name>Default` | the declared `<default>` (KF ≥ 5.78) — for "is this changed?" and reset affordances |
| `Plasmoid.configurationRequired` | `true` shows a Configure button over the representation when the widget cannot work until the user configures it |
| `Plasmoid.metaData.pluginId` / `.version` / `.license` / `.website` | metadata for an About page; `Plasmoid.title` is the translated name |
| `Plasmoid.expanded` | read/write the popup state from your own compact representation |
| `Plasmoid.busy` | draws the theme's busy indicator over the widget while a fetch is in flight |
| `Plasmoid.backgroundHints` | `PlasmaCore.Types.NoBackground` (desktop widgets that should sit flat), `…ShadowBackground`, `…ConfigurableBackground` OR-ed with another value to let the user toggle it |
| `Plasmoid.contextualActions` | the declarative action list (see below) |
| `Plasmoid.status` | `ActiveStatus` / `PassiveStatus` / `NeedsAttentionStatus` for the tray icon |

Contextual actions are **declarative** in Plasma 6. The old imperative
`Component.onCompleted: Plasmoid.setAction("x", …)` + `function action_x()` pair is
gone; put `PlasmaCore.Action { … onTriggered: … }` items in
`Plasmoid.contextualActions: [ … ]` where the bindings and the handler both live
inline.

`Plasmoid.apiVersion` is documented as **do not use** (always `0`).

## Plasma 5 → 6 API mapping

The porting guide's table, condensed — these are the substitutions that matter
when you inherit or copy old code (and what to prefer when writing new code):

| Plasma 5 | Plasma 6 |
|---|---|
| `PlasmaCore.Theme.*` | `Kirigami.Theme.*` (same names, `ColorScope.colorGroup` → `Kirigami.Theme.colorSet`) |
| `PlasmaCore.Units.*` | `Kirigami.Units.*` (`Units.largeSpacing` → `Kirigami.Units.gridUnit`; `mSize(font).height` → `gridUnit`) |
| `PlasmaCore.Units.devicePixelRatio` | `1` (Qt 6 scales by itself) |
| `PlasmaCore.Units.roundtoIconSize(x)` | `Kirigami.Units.iconSizes.roundedIconSize(x)` |
| `PlasmaCore.IconItem` | `Kirigami.Icon` |
| `PlasmaExtras.Heading` | `Kirigami.Heading` |
| `PlasmaCore.Svg` / `SvgItem` / `FrameSvgItem` | `KSvg.Svg` / `KSvg.SvgItem` / `KSvg.FrameSvgItem` (drop the `colorGroup:` property) |
| `PlasmaCore.DataSource` / `DataModel` | `Plasma5Support.DataSource` / `DataModel` |
| `PlasmaCore.SortFilterModel` | `KItemModels.KSortFilterProxyModel` |
| root `Item` | root `PlasmoidItem`; `toolTipMainText`, `fullRepresentation`, … move from the `Plasmoid` attached property to the root item |
| `Plasmoid.nativeInterface.x` (C++ plugin) | `Plasmoid.x` |

Un-version the imports (`import org.kde.kirigami as Kirigami`, not `… 2.4`): Qt 6
does not need it and it causes bugs. PlasmaComponents **2** is removed;
`org.kde.plasma.components` (a.k.a. PlasmaComponents3, QQC2-based) is the one to
use, and `PlasmaExtras.PlaceholderMessage` / `PlasmaExtras.Separator` come from
`org.kde.plasma.extras`.

## i18n

- Wrap every user-visible string in `i18n("…")` with **double quotes** —
  `i18n('…')` is silently skipped by the extraction tooling.
- `i18np("1 item", "%1 items", n)` for plurals; `%1`, `%2` are the arguments.
- The widget's translation domain is `plasma_applet_<Id>` (e.g.
  `plasma_applet_com.example.helloworld`), and the compiled catalogs ship inside
  the package at `contents/locale/<lang>/LC_MESSAGES/plasma_applet_<Id>.mo`.
- `i18nd("plasma_applet_org.kde.plasma.digitalclock", "Show seconds")` reuses
  another widget's translation instead of duplicating the string.
- Workflow: extract `template.pot` + per-language `.po` into `translate/`
  (xgettext/msgmerge/msgfmt from `gettext`), build `.mo` into `contents/locale/`.
  Zren's `translate/merge` + `translate/build` scripts are the reference
  implementation (<https://github.com/Zren/plasma-applet-lib>).
- Test them by overriding the locale for one run:
  `LANGUAGE="fr_CA:fr" LANG="fr_CA.UTF-8" plasmoidviewer -a package` (works with
  `plasmawindowed <id>` for an installed widget).

## HIG points that hit widgets specifically

From <https://develop.kde.org/hig/> — the ones a widget gets wrong most often:

- **Never use colour as the only carrier of meaning** (`status_changes`). A
  traffic-light bar must also carry the number/text; the colour ramp is
  `Kirigami.Theme.highlightColor` → `neutralTextColor` (warning) →
  `negativeTextColor` (error), which is exactly the documented semantic mapping.
- **No important information only in a hover tooltip** (`accessibility`). If the
  data must be read, it belongs in the popup too.
- **Error messages must be actionable** (`status_changes`): say what failed and
  what to do ("Session expired. Run `opencode auth login`"), never "error" alone,
  never silent failure. Blame the third party when the third party is at fault.
- **Minimise status messages**; show success by changing something visible rather
  than announcing it.
- **Tray icons**: the HIG asks for opt-in, and ideally visible *only when there is
  abnormal status*. A usage widget that lives in the tray permanently is a
  deliberate exception the user should have chosen — which is why the tray text /
  presence should be a setting (`X-Plasma-NotificationArea` + user enablement)
  rather than a forced default.
- Radio buttons for ≤ 3 options, a `ComboBox` beyond that.
- Test with a different system colour scheme, system font size 14, animations
  disabled, keyboard-only, and a screen reader; verify nothing is only in audio,
  nothing is cut off, and animated elements degrade to a static frame.
- Negative language to avoid: kill→close, execute→run, abort→exit, fatal→critical.
- Name items with the distinctive part first ("Germany (Europe)", not
  "Europe/Germany").

## Where the upstream docs are stale (as of the pages fetched for this skill)

- `docs/plasma/widget/configuration/` still shows a bare `Kirigami.FormLayout` as
  the config page root. That is out of date: the porting guide requires one of the
  KCM components and the dialog itself needs a `Page` for the heading and padding.
  See `references/settings.md` — the measured behaviour wins.
- Most code samples on those pages still use versioned imports
  (`import org.kde.plasma.core 2.0`) and `PlasmaCore.Units`, both superseded.
- `PlasmaCore.Units.devicePixelRatio` appears in sizing samples; in Qt 6 the
  documented value is `1` and you should not multiply by it.
- The tutorial's `package/` directory convention (metadata.json inside a
  `package/` subdir) is a packaging convention for zips, not a requirement:
  `kpackagetool6 --install <dir>` is happy with `metadata.json` + `contents/` at
  the top level of the directory you point it at.
