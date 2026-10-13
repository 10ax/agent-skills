#!/usr/bin/env bash
#
# Development helper for a Plasma 6 applet. Replace the __PLACEHOLDER__ values.
# Keep the source tree outside ~/.local/share/plasma/plasmoids and install from
# here so the installed copy is always reproducible.
#
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
package_id="__reverse.dns.id__"
package_type="Plasma/Applet"

# Optional: a shell helper the QML calls through the executable data source.
helper="$script_dir/contents/scripts/__helper__"

# Optional: icons must live in the icon theme to be resolvable by name.
icon_theme_dir="$HOME/.local/share/icons/hicolor/scalable/apps"
icon_files=(__icon__.svg __icon__-symbolic.svg)

usage() {
    cat <<'USAGE'
Usage: ./dev.sh <command>

Commands:
  doctor       Check dependencies and run one live smoke test.
  usage        Print the data the widget consumes (helper json).
  install      Install for the current user and reload Plasma Shell.
  upgrade      Upgrade the installed package and reload Plasma Shell.
  reinstall    Remove, install, and reload.
  remove       Remove the package (and its installed icons).
  reload       Restart Plasma Shell without logging out.
  preview      Open the widget: plasmoidviewer (plasma-sdk) or plasmawindowed.
  status       Show installed package info.
  validate     Syntax + package checks, without touching the live install.
USAGE
}

have() { command -v "$1" >/dev/null 2>&1; }

require_command() {
    have "$1" || { printf 'Missing required command: %s\n' "$1" >&2; exit 127; }
}

is_installed() {
    kpackagetool6 --type "$package_type" --show "$package_id" >/dev/null 2>&1
}

reload_plasma() {
    if systemctl --user list-unit-files plasma-plasmashell.service >/dev/null 2>&1; then
        systemctl --user restart plasma-plasmashell.service
        return
    fi
    if have kquitapp6 && have kstart; then
        kquitapp6 plasmashell || true
        kstart plasmashell >/dev/null 2>&1 &
        return
    fi
    printf 'Could not reload Plasma Shell automatically. Log out and back in.\n' >&2
}

install_icons() {
    [ -d "$script_dir/contents/icons" ] || return 0
    mkdir -p "$icon_theme_dir"
    for icon in "${icon_files[@]}"; do
        [ -e "$script_dir/contents/icons/$icon" ] && \
            install -m 0644 "$script_dir/contents/icons/$icon" "$icon_theme_dir/$icon"
    done
    have kbuildsycoca6 && kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
}

remove_icons() {
    for icon in "${icon_files[@]}"; do rm -f "$icon_theme_dir/$icon"; done
}

install_package()   { require_command kpackagetool6; kpackagetool6 --type "$package_type" --install "$script_dir"; install_icons; }
upgrade_package()   { require_command kpackagetool6; kpackagetool6 --type "$package_type" --upgrade "$script_dir"; install_icons; }
remove_package()    { require_command kpackagetool6; kpackagetool6 --type "$package_type" --remove "$package_id"; remove_icons; }

validate() {
    local failed=0

    printf '== syntax ==\n'
    if [ -x "$helper" ]; then
        bash -n "$helper" && printf 'ok: helper parses\n' || { printf 'fail: helper syntax\n'; failed=1; }
    fi
    if have jq && jq -e . "$script_dir/metadata.json" >/dev/null 2>&1; then
        printf 'ok: metadata.json parses\n'
    else
        printf 'fail: metadata.json\n'; failed=1
    fi
    if have qmllint6; then qml_bin=qmllint6; elif [ -x /usr/lib/qt6/bin/qmllint ]; then qml_bin=/usr/lib/qt6/bin/qmllint; else qml_bin=""; fi
    if [ -n "$qml_bin" ]; then
        # i18n() is reported as an unqualified access in plasmoids, but so is a
        # typo'd id or property. Drop only warnings whose own source line is an
        # i18n call, so a real typo still fails this check.
        lint_targets=()
        for f in "$script_dir"/contents/ui/*.qml "$script_dir"/contents/js/*.js; do
            [ -e "$f" ] && lint_targets+=("$f")
        done
        if [ "${#lint_targets[@]}" -gt 0 ]; then
            lint_output=$("$qml_bin" -I /usr/lib/qt6/qml "${lint_targets[@]}" 2>&1 | awk '
                /^(Warning|Error):/ {
                    warning = $0
                    getline source
                    if (warning ~ /Unqualified access \[unqualified\]$/ && source ~ /i18n[cndp]*\(/) next
                    print warning
                }' || true)
            if [ -n "$lint_output" ]; then
                printf '%s\n' "$lint_output"; printf 'fail: qmllint reported issues\n'; failed=1
            else
                printf 'ok: qmllint (%s files)\n' "${#lint_targets[@]}"
            fi
        fi
    fi
    # Optional unit tests for the pure helpers in contents/js/.
    if [ -d "$script_dir/contents/tests" ]; then
        if have qmltestrunner; then tst_bin=qmltestrunner; elif [ -x /usr/lib/qt6/bin/qmltestrunner ]; then tst_bin=/usr/lib/qt6/bin/qmltestrunner; else tst_bin=""; fi
        if [ -z "$tst_bin" ]; then
            printf 'skip: qmltestrunner not found\n'
        elif QT_QPA_PLATFORM=offscreen "$tst_bin" -input "$script_dir/contents/tests" >/dev/null 2>&1; then
            printf 'ok: unit tests\n'
        else
            printf 'fail: unit tests\n'; failed=1
        fi
    fi

    printf '== files ==\n'
    for file in metadata.json contents/ui/main.qml; do
        if [ -e "$script_dir/$file" ]; then printf 'ok: %s\n' "$file"; else printf 'fail: missing %s\n' "$file"; failed=1; fi
    done

    # Settings are optional. When they exist, check the XML parses and that every
    # page config.qml names actually resolves: a page that does not shows up as an
    # empty or missing settings dialog, which is hard to diagnose from outside.
    if [ -e "$script_dir/contents/config/main.xml" ]; then
        if ! have xmllint; then
            printf 'skip: xmllint not installed, config/main.xml unchecked\n'
        elif xmllint --noout "$script_dir/contents/config/main.xml"; then
            printf 'ok: contents/config/main.xml parses\n'
        else
            printf 'fail: contents/config/main.xml does not parse\n'; failed=1
        fi
        for page in $(sed -n 's/.*source:[[:space:]]*"\([^"]*\)".*/\1/p' "$script_dir/contents/config/config.qml"); do
            if [ -e "$script_dir/contents/ui/$page" ]; then
                printf 'ok: contents/ui/%s\n' "$page"
            else
                printf 'fail: config.qml references missing contents/ui/%s\n' "$page"; failed=1
            fi
        done
    fi

    printf '== kpackage (into a throwaway root) ==\n'
    if have kpackagetool6; then
        local root; root=$(mktemp -d)
        if kpackagetool6 --type "$package_type" --packageroot "$root" --install "$script_dir" >/dev/null; then
            printf 'ok: package structure accepted\n'
        else
            printf 'fail: kpackagetool6 rejected the package\n'; failed=1
        fi
        rm -rf "$root"
    fi

    [ "$failed" -eq 0 ] && printf 'result: ok\n' || printf 'result: problems found\n'
    return "$failed"
}

case "${1:-}" in
    doctor)  [ -x "$helper" ] && "$helper" doctor ;;
    usage)   "$helper" json ;;
    install)   install_package; reload_plasma; printf 'installed %s\n' "$package_id" ;;
    upgrade)   if is_installed; then upgrade_package; else install_package; fi; reload_plasma; printf 'installed %s\n' "$package_id" ;;
    reinstall) is_installed && remove_package || true; install_package; reload_plasma ;;
    remove)    remove_package; reload_plasma ;;
    reload)    reload_plasma ;;
    preview)
        # plasmawindowed ships with plasma-workspace but needs the package installed;
        # plasmoidviewer needs plasma-sdk and can also run an uninstalled folder.
        if have plasmoidviewer; then
            plasmoidviewer -a "$package_id"
        elif have plasmawindowed && is_installed; then
            plasmawindowed "$package_id"
        elif have plasmawindowed; then
            printf 'Not installed yet: ./dev.sh upgrade, then ./dev.sh preview (plasmawindowed).\n' >&2
            exit 1
        else
            printf 'Neither plasmoidviewer (plasma-sdk) nor plasmawindowed found.\n' >&2
            exit 127
        fi ;;
    status)  require_command kpackagetool6; kpackagetool6 --type "$package_type" --show "$package_id" ;;
    validate) validate ;;
    -h|--help|help) usage ;;
    *) usage >&2; exit 64 ;;
esac
