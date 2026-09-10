#!/usr/bin/env bash
# Stop: a turn that changed the tree does not end on a red bin/ci. Exit 2 keeps
# the turn going and hands back the failed steps; the full run goes to tmp/ci.log
# because the Setup step clears log/ while it runs.
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:?}"

# A tree that matches HEAD holds nothing this turn could have broken.
[ -n "$(git status --porcelain)" ] || exit 0

log=tmp/ci.log
bin/ci >"$log" 2>&1 && exit 0

{
  echo "bin/ci failed; the full output is in $log"
  # A run that dies before reporting any step leaves its cause at the end.
  grep -F "❌" "$log" | perl -pe 's/\e\[[0-9;]*m//g' || tail -n 20 "$log"
} >&2
exit 2
