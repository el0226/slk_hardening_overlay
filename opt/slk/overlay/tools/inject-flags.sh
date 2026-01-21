#!/bin/sh
# Mechanical injector: edits SlackBuilds in the work tree to append $HARDEN_CFLAGS
# wherever they hard-set CFLAGS/CXXFLAGS to SLKCFLAGS; also preserves global LDFLAGS
# when SlackBuilds reset/export it to SLKLDFLAGS.
set -eu

#WORK_ROOT="${WORK_ROOT:-/opt/slk/work/tree}"
#OVERLAY_ROOT="${OVERLAY_ROOT:-/opt/slk/overlay}"
EXCEPTIONS="${EXCEPTIONS:-$OVERLAY_ROOT/config/exceptions.list}"

if [ ! -d "$WORK_ROOT" ]; then
  echo "<< ERROR: WORK_ROOT not found: $WORK_ROOT" >&2
  exit 1
fi

# Ensure hardening variables exist for injected references
if [ -z "${HARDEN_CFLAGS:-}" ] || [ -z "${HARDEN_LDFLAGS:-}" ]; then
  if [ -f "$OVERLAY_ROOT/config/hardening.env" ]; then
    . "$OVERLAY_ROOT/config/hardening.env"
  else
    echo "<< ERROR: HARDEN_CFLAGS/HARDEN_LDFLAGS not set and hardening.env not found." >&2
    exit 1
  fi
fi

# Build a quick lookup set for exceptions.
TMP_EXC="$(mktemp)"
trap 'rm -f "$TMP_EXC"' EXIT
if [ -f "$EXCEPTIONS" ]; then
  grep -v '^[[:space:]]*$' "$EXCEPTIONS" | grep -v '^[[:space:]]*#' > "$TMP_EXC" || true
else
  : > "$TMP_EXC"
fi

changed=0
scanned=0

find "$WORK_ROOT" -type f -name '*.SlackBuild' | while read -r f; do
  rel="${f#$WORK_ROOT/}"
  scanned=$((scanned+1))

  if grep -qxF "$rel" "$TMP_EXC"; then
    continue
  fi

  # Edit in place; Perl returns 0 even if no changes, so we detect changes by mtime hash.
  before="$(sha256sum "$f" | awk '{print $1}')"
  perl "$OVERLAY_ROOT/tools/inject-flags.pl" "$f"
  after="$(sha256sum "$f" | awk '{print $1}')"

  if [ "$before" != "$after" ]; then
    changed=$((changed+1))
  fi
done

# The loop above runs in a subshell under some /bin/sh implementations.
# Provide a cheap aggregate by grepping for injected marker usage.
echo "Build Flags :: Ok"
