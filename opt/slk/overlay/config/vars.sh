export OVERLAY_ROOT=/opt/slk/overlay
export UPSTREAM_ROOT=/opt/slk/upstream/source
export WORK_ROOT=/opt/slk/work/tree
export BUILDLIST=$OVERLAY_ROOT/config/build.lst
export TMP=/tmp/overlay

. $OVERLAY_ROOT/config/hardening.env

echo ""
echo ">> Slackware $(uname -m) hardening overlay"
echo "Author.....: <el0226@slackware>"
echo ""
echo ">> Paths"
echo "Overlay....: $OVERLAY_ROOT"
echo "Upstream...: $UPSTREAM_ROOT"
echo "Workspace..: $WORK_ROOT"
echo "Build List.: $BUILDLIST"
echo ""
echo ">> Build Flags used for Hardening"
echo "CFLAGS.....: $HARDEN_CFLAGS"
echo "LDFLAGS....: $HARDEN_LDFLAGS"
echo""

