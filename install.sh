#!/usr/bin/env bash
# install.sh - install the two-pass humanizer pipeline into your agent's skills dir
#
#   ./install.sh              symlink both skills into ~/.claude/skills (updates follow git pull)
#   ./install.sh --copy       install independent copies instead
#   ./install.sh --project    install into ./.claude/skills of the current dir
#   ./install.sh --force      replace an existing install (backs it up first)
#
# Pass 1 is this repo's own humanizer (SKILL.md at the root).
# Pass 2 is structural-humanizer, vendored from NulightJens/humanizer-stack.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS=(humanizer structural-humanizer)
MODE=link
TARGET="$HOME/.claude/skills"
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)    MODE=copy ;;
    --project) TARGET="$PWD/.claude/skills" ;;
    --force)   FORCE=1 ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [[ "$TARGET" == "$REPO/.claude/skills" ]]; then
  echo "that is where the skills already live; nothing to do" >&2
  exit 2
fi

mkdir -p "$TARGET"
echo "installing into $TARGET (mode: $MODE)"

for skill in "${SKILLS[@]}"; do
  src="$REPO/.claude/skills/$skill"
  dst="$TARGET/$skill"

  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ "$FORCE" -eq 0 ]]; then
      echo "  SKIP $skill: already exists at $dst"
      echo "       re-run with --force to replace it (a backup is kept)"
      continue
    fi
    backup="$dst.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup"
    echo "  backed up existing $skill to $(basename "$backup")"
  fi

  if [[ "$MODE" == link ]]; then
    ln -s "$src" "$dst"
    echo "  linked $skill"
  else
    # -L dereferences humanizer/SKILL.md, which points at the repo root SKILL.md
    cp -RL "$src" "$dst"
    echo "  copied $skill"
  fi
done

chmod +x "$REPO/scripts/copy_scan.py" \
         "$REPO/.claude/skills/structural-humanizer/scripts/structural_scan.py" 2>/dev/null || true

cat <<EOF

done. verify with:
  ls -la $TARGET | grep humanizer

run the scanners:
  python3 $REPO/scripts/copy_scan.py <file>
  python3 $REPO/.claude/skills/structural-humanizer/scripts/structural_scan.py <file>

then start a new agent session so the skills load.
EOF
