#!/usr/bin/env bash
# Symlink every skill in this repo into a runtime's skills directory.
#
#   ./install.sh                  link into ~/.claude/skills
#   ./install.sh ~/.agents/skills link into the cross-runtime alias instead
#   ./install.sh --list           show what is linked, without changing anything
#
# Symlinks rather than copies, so editing a skill here takes effect in the next
# session. A target that exists and is not one of our symlinks is never touched.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=install
TARGET="${HOME}/.claude/skills"

case "${1-}" in
  --list) MODE=list ;;
  -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "") ;;
  *) TARGET="${1%/}" ;;
esac

# Every directory holding a SKILL.md, under skills/ and forks/ alike.
skill_dirs() {
  find "$REPO/skills" "$REPO/forks" -mindepth 1 -maxdepth 2 -name SKILL.md -print0 2>/dev/null |
    xargs -0 -r -n1 dirname | sort
}

if [[ $MODE == list ]]; then
  printf '%-28s %s\n' SKILL STATUS
  while read -r dir; do
    [[ -n $dir ]] || continue
    name="$(basename "$dir")"; link="$TARGET/$name"
    if [[ -L $link ]]; then
      dest="$(readlink -f "$link" || true)"
      if [[ $dest == "$(readlink -f "$dir")" ]]; then status="linked"; else status="LINKED ELSEWHERE -> $dest"; fi
    elif [[ -e $link ]]; then status="BLOCKED, real path exists"
    else status="not installed"
    fi
    printf '%-28s %s\n' "$name" "$status"
  done < <(skill_dirs)
  # Dangling links left behind by a renamed or deleted skill.
  if [[ -d $TARGET ]]; then
    for link in "$TARGET"/*; do
      [[ -L $link && ! -e $link ]] || continue
      printf '%-28s %s\n' "$(basename "$link")" "STALE, target gone"
    done
  fi
  exit 0
fi

[[ -d $TARGET ]] || { echo "creating $TARGET"; mkdir -p "$TARGET"; }

linked=0 skipped=0
while read -r dir; do
  [[ -n $dir ]] || continue
  name="$(basename "$dir")"; link="$TARGET/$name"
  if [[ -L $link ]]; then
    ln -sfn "$dir" "$link"; echo "relinked  $name"; linked=$((linked+1))
  elif [[ -e $link ]]; then
    echo "SKIPPED   $name: $link exists and is not a symlink, leaving it alone" >&2
    skipped=$((skipped+1))
  else
    ln -s "$dir" "$link"; echo "linked    $name"; linked=$((linked+1))
  fi
done < <(skill_dirs)

echo "$linked linked, $skipped skipped. Run '$0 --list' to verify."
[[ $skipped -eq 0 ]]
