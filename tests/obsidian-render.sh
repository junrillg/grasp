#!/usr/bin/env bash
# Renders pages in the real Obsidian app (Reading view) and counts what came out.
# Usage: tests/obsidian-render.sh [FOLDER...]      default: docs/how-it-works
#
# For each .md page: every ```mermaid fence must become a drawn diagram, with no parse error and
# no broken image. A page with a deliberately broken diagram runs first, to prove a failure
# would be seen.
#
# Needs: the Obsidian app running, its command line switched on (Settings > General > Advanced),
# and tests/render registered as a vault named "render". Pages are copied into that vault for the
# run and removed after; it opens them in the background and does not take keyboard focus.
# Exit 0: every diagram rendered. 1: something did not. 2: Obsidian is not available (skipped).
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VAULT=render
TMP="$ROOT/tests/render/tmp-check"

ob() { obsidian vault="$VAULT" "$@" 2>&1 </dev/null; }   # </dev/null: it must not eat the page list

command -v obsidian >/dev/null 2>&1 || { echo "skip: no obsidian command on the path" >&2; exit 2; }
ob vault | grep -q "tests/render" || { echo "skip: Obsidian's command line is off, or tests/render is not a vault named \"$VAULT\"" >&2; exit 2; }

cleanup() { rm -rf "$TMP"; }   # the vault's workspace.json is git-ignored: Obsidian rewrites it
trap cleanup EXIT
rm -rf "$TMP"; mkdir -p "$TMP"

# what the page shows after scrolling through it once (Reading view draws a page lazily)
read -r -d '' SWEEP <<'EOF'
const sleep = ms => new Promise(r => setTimeout(r, ms));
const v = app.workspace.activeLeaf.view;
if (v.getMode() !== 'preview') { app.commands.executeCommandById('markdown:toggle-preview') }
await sleep(1500);
const sc = v.containerEl.querySelector('.markdown-reading-view .markdown-preview-view');
const ok = new Set(), bad = new Set(), badImg = new Set();
for (let y = 0; ; y += 450) {
  sc.scrollTop = y; await sleep(300);
  v.containerEl.querySelectorAll('.markdown-reading-view .mermaid').forEach(e => {
    const k = e.textContent.slice(0, 240);
    if (e.querySelector('[class*="error"]')) bad.add(k); else if (e.querySelector('svg')) ok.add(k);
  });
  v.containerEl.querySelectorAll('.markdown-reading-view img').forEach(i => { if (i.complete && i.naturalWidth === 0) badImg.add(i.src) });
  if (y > sc.scrollHeight) break;
}
sc.scrollTop = 0;
return [v.getMode(), v.file.path, ok.size, bad.size, badImg.size].join('\t');
EOF

# open_page VAULT_PATH: Obsidian needs a moment to notice a file that was just copied in
open_page() {
  local i
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    [[ "$(ob open path="$1")" == Opened* ]] && { sleep 2; return 0; }
    sleep 0.5
  done
  return 1
}

# check_page VAULT_PATH WANT_DIAGRAMS -> prints one line; returns 1 when the page is wrong
check_page() {
  local path=$1 want=$2 res mode file got err img
  open_page "$path" || { printf 'FAIL  Obsidian could not open  %s\n' "${path#tmp-check/}"; return 1; }
  res=$(ob eval code="$SWEEP" | tail -n 1); res=${res#=> }
  IFS=$'\t' read -r mode file got err img <<< "$res"
  if [[ "$mode" == preview && "$file" == "$path" && "$got" == "$want" && "$err" == 0 && "$img" == 0 ]]; then
    printf 'ok    %s diagrams  %s\n' "$got" "${path#tmp-check/}"; return 0
  fi
  printf 'FAIL  wanted %s diagrams, drew %s, errors %s, broken images %s  %s\n' "$want" "${got:-?}" "${err:-?}" "${img:-?}" "${path#tmp-check/}"
  return 1
}

# the control: one good diagram and one broken one must read as "1 drawn, 1 error"
printf 'Good:\n\n```mermaid\nflowchart LR\n  A["ok"] --> B["fine"]\n```\n\nBroken:\n\n```mermaid\nflowchart LR\n  A["unclosed --> B\n  C --x--> \n```\n' > "$TMP/control.md"
open_page tmp-check/control.md || { echo "FAIL  control: Obsidian could not open the control page" >&2; exit 1; }
ctl=$(ob eval code="$SWEEP" | tail -n 1); ctl=${ctl#=> }
IFS=$'\t' read -r _ _ cgot cerr _ <<< "$ctl"
[[ "${cgot:-}" == 1 && "${cerr:-}" == 1 ]] || { echo "FAIL  control: a broken diagram was not reported (drew ${cgot:-?}, errors ${cerr:-?}); results below can't be trusted" >&2; exit 1; }
echo "ok    control: a broken diagram is reported"

bad=0 pages=0 total=0 n=0
[[ $# -gt 0 ]] || set -- "$ROOT/docs/how-it-works"
for folder in "$@"; do
  [[ -d "$folder" ]] || { echo "no such folder: $folder" >&2; exit 2; }
  n=$((n + 1)); cp -R "$folder" "$TMP/set$n"
  while IFS= read -r f; do
    want=$(grep -c '^```mermaid' "$ROOT/tests/render/$f")
    pages=$((pages + 1)); total=$((total + want))
    check_page "$f" "$want" || bad=1
  done < <(cd "$ROOT/tests/render" && find "tmp-check/set$n" -name '*.md' | LC_ALL=C sort)
done
printf '\n%d pages, %d diagrams, Reading view: %s\n' "$pages" "$total" "$([[ $bad == 0 ]] && echo 'all drawn' || echo 'SOME FAILED')"
exit $bad
