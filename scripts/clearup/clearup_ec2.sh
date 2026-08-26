#!/bin/bash
# Frees disk space on the group EC2 instance by removing build artifacts,
# run outputs, and temp download data. Safe to re-run at any time -- these
# are only regenerated (by setup_ec2.sh / build_jules.sh / get_run_directory.sh
# / run_jules.sh), never hand-edited, so nothing here is unique or backed up
# anywhere else.
#
# Default: "soft" clean -- removes run outputs and build artifacts, keeps
# the installed toolchain (Miniforge, FCM, JULES source) so the next build
# is fast.
#
# Pass --deep to also remove the toolchain itself and reset the instance
# back to a pre-setup_ec2.sh state (e.g. before handing the instance off
# to someone else, or freeing space on a small root volume).
set -e

DEEP=false
[ "$1" = "--deep" ] && DEEP=true

echo "Disk usage before cleanup:"
df -h "$HOME" | tail -1

# Run output and downloaded run directories (safe -- regenerate with
# get_run_directory.sh + run_jules.sh)
rm -rf "$HOME"/my_first_run "$HOME"/*_run
rm -rf /tmp/jules-tutorial-data /tmp/jules-tutorial-data.tar.gz

# Build artifacts (safe -- regenerate with build_jules.sh, ~1 minute)
rm -rf "$HOME/jules_build"

# pip/conda caches (safe -- just re-downloaded on next install)
[ -d "$HOME/miniforge3" ] && source "$HOME/miniforge3/bin/activate" && conda clean -y --all -q 2>/dev/null || true
pip cache purge -q 2>/dev/null || true

if [ "$DEEP" = true ]; then
  echo "Deep clean: also removing the toolchain (Miniforge, FCM, JULES source)."
  rm -rf "$HOME/miniforge3" "$HOME/fcm" "$HOME/jules_source"
  # Leave the swapfile alone -- it's instance infrastructure, not tutorial
  # state, and re-creating it needs sudo + a few seconds either way.
fi

echo
echo "Disk usage after cleanup:"
df -h "$HOME" | tail -1
echo "Done. Re-run setup_ec2.sh (and build_jules.sh if --deep was used) to start again."
