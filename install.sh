#!/usr/bin/env bash
# Link the grasp skill into each agent's skills folder, so a git pull updates it everywhere.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install.sh [--project DIR] [--copy] [--uninstall] [-h]

  (no flags)     link skills/grasp into ~/.claude/skills and ~/.agents/skills
                 (~/.agents/skills is read by Codex, Cursor and Gemini CLI)
  --project DIR  install into DIR/.claude/skills and DIR/.agents/skills instead
  --copy         copy instead of linking (no updates on git pull; /grasp update re-copies
                 from this repository, recorded in the copy's .source file)
  --uninstall    remove what this script installed
EOF
}

repo="$(cd "$(dirname "$0")" && pwd)"
src="$repo/skills/grasp"
base="$HOME" mode=link action=install
while [ $# -gt 0 ]; do
  case "$1" in
    --project) [ $# -ge 2 ] || { usage; exit 2; }; base="$(cd "$2" && pwd)"; shift ;;
    --copy) mode=copy ;;
    --uninstall) action=uninstall ;;
    -h|--help|help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
  shift
done

for dir in "$base/.claude/skills" "$base/.agents/skills"; do
  dest="$dir/grasp"
  if [ "$action" = uninstall ]; then
    # only what this script made: its symlink, or its copy (marked by .source)
    if [ -L "$dest" ]; then rm -f "$dest"; echo "removed $dest"
    elif [ -f "$dest/.source" ]; then rm -rf "$dest"; echo "removed $dest"
    elif [ -e "$dest" ]; then echo "skip $dest: not installed by this script" >&2
    fi
    continue
  fi
  mkdir -p "$dir"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    if [ -f "$dest/.source" ]; then
      rm -rf "$dest"   # grasp's own earlier copy: replace it
    else
      echo "skip $dest: a real folder is there; remove it first" >&2
      continue
    fi
  fi
  rm -f "$dest"
  if [ "$mode" = copy ]; then
    cp -R "$src" "$dest"
    printf '%s\n' "$repo" > "$dest/.source"   # lets /grasp update re-copy from here
  else
    ln -s "$src" "$dest"
  fi
  echo "$mode $dest"
done
