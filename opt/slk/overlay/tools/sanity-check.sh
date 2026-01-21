#!/bin/sh
# Basic validation that the injector did its job (ignores commented-out lines).
set -eu

#WORK_ROOT="${WORK_ROOT:-/opt/slk/work/tree}"
#OVERLAY_ROOT="${OVERLAY_ROOT:-/opt/slk/overlay}"
EXCEPTIONS="${EXCEPTIONS:-$OVERLAY_ROOT/config/exceptions.list}"

[ -d "$WORK_ROOT" ] || { echo "<< ERROR: WORK_ROOT not found: $WORK_ROOT" >&2; exit 1; }

TMP_EXC="$(mktemp)"
trap 'rm -f "$TMP_EXC"' EXIT
if [ -f "$EXCEPTIONS" ]; then
  grep -v '^[[:space:]]*$' "$EXCEPTIONS" | grep -v '^[[:space:]]*#' > "$TMP_EXC" || true
else
  : > "$TMP_EXC"
fi

bad=0

while read -r f; do
  rel="${f#$WORK_ROOT/}"
  if grep -qxF "$rel" "$TMP_EXC"; then
    continue
  fi

  # Ignore comment lines for the checks:
  active="$(grep -v '^[[:space:]]*#' "$f" || true)"

		echo "$active" | grep -q 'CFLAGS="$SLKCFLAGS"' &&     ! echo "$active" | grep -q 'CFLAGS="$SLKCFLAGS $HARDEN_CFLAGS"' &&     { echo "<< Missing HARDEN_CFLAGS in: $rel"; bad=$((bad+1)); }

  echo "$active" | grep -q 'CXXFLAGS="$SLKCFLAGS"' &&     ! echo "$active" | grep -q 'CXXFLAGS="$SLKCFLAGS $HARDEN_CFLAGS"' &&     { echo "<< Missing HARDEN_CFLAGS in: $rel"; bad=$((bad+1)); }

done <<EOF
$(find "$WORK_ROOT" -type f -name '*.SlackBuild')
EOF

if [ "$bad" -ne 0 ]; then
  echo "<< Sanity check FAILED: $bad SlackBuild(s) still set SLKCFLAGS without HARDEN_CFLAGS." >&2
  exit 1
else
	echo "Sanity Verified :: Ok"
	sleep 1
fi
