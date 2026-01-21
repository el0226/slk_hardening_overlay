#!/bin/sh
# Create a throwaway work tree from the pristine upstream mirror.
set -eu

#UPSTREAM_ROOT="${UPSTREAM_ROOT:-/opt/slk/upstream/source}"
#WORK_ROOT="${WORK_ROOT:-/opt/slk/work/tree}"

if [ ! -d "$UPSTREAM_ROOT" ]; then
  echo "<< ERROR: UPSTREAM_ROOT not found: $UPSTREAM_ROOT" >&2
  exit 1
else
	echo ">> Setting up Workspace"
fi

mkdir -p "$(dirname "$WORK_ROOT")"

# Prefer reflink copies when supported; fall back to rsync.
if cp -a --reflink=auto "$UPSTREAM_ROOT" "$WORK_ROOT.tmp" 2>/dev/null; then
  rm -rf "$WORK_ROOT"
  mv "$WORK_ROOT.tmp" "$WORK_ROOT"
else
  rm -rf "$WORK_ROOT"
  mkdir -p "$WORK_ROOT"
  rsync -aH --delete "$UPSTREAM_ROOT"/ "$WORK_ROOT"/
fi

#echo "Workspace Status :: Ok"
echo "..."
