# slk_hardening_overlay

* Rebuild Slackware Linux from source with hardened compiler flags
* Originally written and designed with ChatGPT AI aid 
* Some information below may need updating to match code

The build list is in $OVERLAY_ROOT/config/build.lst.  It can be
created manually.  By default the contents are generated using the
tools/mklist.sh shell script.  The default is to use the package
series designated.  The "run" script contains the series list settting
and should be edited by the user.

# Update the package series in $OVERLAY_ROOT/run 
- `export SERIES_LIST="a ap d l n"`

* TODO: Define package build lists to drop into builds.

## Slackware x86_64 hardening overlay (rebase-friendly)

This overlay is designed for:
- A pristine rsync mirror of Slackware's `source/` tree (never edited)
- A throwaway work tree regenerated after each rsync
- Mechanical injection of hardening flags into SlackBuilds that hard-set `CFLAGS/CXXFLAGS` to `SLKCFLAGS`
- A small, optional patch series for true exceptions

## Directory layout (recommended)

- `/opt/slk/upstream/source`  : pristine mirror (rsync target)
- `/opt/slk/overlay`          : this overlay (git repo recommended)
- `/opt/slk/work/tree`        : regenerated work tree you build from

## What the injector changes

It edits SlackBuilds to append `$HARDEN_CFLAGS` when they do any of:
- `CFLAGS="$SLKCFLAGS"`
- `export CFLAGS="$SLKCFLAGS"`
- `-DCMAKE_C_FLAGS...="$SLKCFLAGS"` (and CXX)

It also patches SlackBuilds that reset/export `LDFLAGS` to `SLKLDFLAGS` so they preserve any
global `LDFLAGS` you exported (including `$HARDEN_LDFLAGS`).

## Quick start

1) Put the overlay in place:
   - Copy this directory to `/opt/slk/overlay`
   - Optionally `git init` and commit it

2) Maintain a pristine upstream mirror:
   - rsync Slackware's `source/` into `/opt/slk/upstream/source`
     (do not edit this tree)

3) Build a work tree + apply overlay:

   ```sh
   export OVERLAY_ROOT=/opt/slk/overlay
   export UPSTREAM_ROOT=/opt/slk/upstream/source
   export WORK_ROOT=/opt/slk/work/tree

   . $OVERLAY_ROOT/config/hardening.env
   $OVERLAY_ROOT/tools/make-worktree.sh
   $OVERLAY_ROOT/tools/inject-flags.sh
   $OVERLAY_ROOT/tools/apply-patches.sh
   $OVERLAY_ROOT/tools/sanity-check.sh
   $OVERLAY_ROOT/tools/mklist.sh
   ```

4) Build packages from `$WORK_ROOT` using your normal process.

## After each rsync update

Re-run steps (3) and rebuild what you want. No rebasing/merging is required because you never
carry local edits in the upstream tree.

## Managing exceptions

- If a SlackBuild truly must not be edited, add its path (relative to `$WORK_ROOT`) to:
  `config/exceptions.list`
- If a package needs a real fix, add a small patch under `patches/` and list it in `patches/series`

## Notes

- This is a Phase-1 "mostly compatible" hardening profile (no PIE by default).
- Use `readelf` or `checksec` to confirm RELRO/canary/fortify/NX results on built binaries.
