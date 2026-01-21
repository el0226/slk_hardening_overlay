#!/bin/sh
# Apply small exception patches after injection.
set -eu

#WORK_ROOT="${WORK_ROOT:-/opt/slk/work/tree}"
#OVERLAY_ROOT="${OVERLAY_ROOT:-/opt/slk/overlay}"
SERIES="$OVERLAY_ROOT/patches/series"

[ -d "$WORK_ROOT" ] || { echo "<< ERROR: WORK_ROOT not found: $WORK_ROOT" >&2; exit 1; }

if [ ! -s "$SERIES" ]; then
  echo "Apply Patch :: No patches to apply. " 
  exit 0
fi

cd "$WORK_ROOT"

while read -r p; do
  case "$p" in
    ""|\#*) continue ;;
  esac
  patchfile="$OVERLAY_ROOT/patches/$p"
  [ -f "$patchfile" ] || { echo "ERROR: missing patch: $patchfile" >&2; exit 1; }
  echo "Apply Patch :: $p"
  patch -p1 < "$patchfile"
done < "$SERIES"
