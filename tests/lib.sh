# Plain-bash test helpers. Source this file, define test_* functions, then call run_tests.
PASS=0
FAIL=0
FAILED_NAMES=()

_fail() { printf '  FAIL: %s\n' "$1" >&2; CURRENT_FAILED=1; }

assert_eq() { # EXPECTED ACTUAL MSG
  if [[ "$1" != "$2" ]]; then
    _fail "$3"
    printf '    expected: %q\n    actual:   %q\n' "$1" "$2" >&2
  fi
}

assert_contains() { # HAYSTACK NEEDLE MSG
  if [[ "$1" != *"$2"* ]]; then
    _fail "$3"
    printf '    missing: %q\n' "$2" >&2
  fi
}

assert_exit() { # CODE MSG -- CMD...
  local want=$1 msg=$2
  shift 2
  [[ "$1" == "--" ]] && shift
  local got=0
  "$@" >/dev/null 2>&1 || got=$?
  if [[ "$got" != "$want" ]]; then
    _fail "$msg"
    printf '    expected exit %s, got %s\n' "$want" "$got" >&2
  fi
}

assert_file_eq() { # PATH_A PATH_B MSG
  if ! cmp -s "$1" "$2"; then
    _fail "$3"
    diff <(od -c "$1") <(od -c "$2") | head -20 >&2
  fi
}

new_tmp() { mktemp -d "${TMPDIR:-/tmp}/grasp-test.XXXXXX"; }

run_tests() { # optional filter regex as $1
  local filter=${1:-.} t rc
  for t in $(declare -F | awk '{print $3}' | grep '^test_' | grep -E -- "$filter"); do
    rc=0
    ( CURRENT_FAILED=0; "$t"; exit "$CURRENT_FAILED" ) || rc=$?
    if [[ $rc == 0 ]]; then PASS=$((PASS + 1)); printf 'ok   %s\n' "$t"
    else FAIL=$((FAIL + 1)); FAILED_NAMES+=("$t"); printf 'FAIL %s\n' "$t"; fi
  done
  printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
  [[ $FAIL == 0 ]]
}
