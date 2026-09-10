#!/usr/bin/env bash
# PostToolUse(Edit|Write): hold the edited file to the check that owns it.
# Exit 2 is what hands a failure back; any other exit leaves it in the debug log.
set -euo pipefail

root="${CLAUDE_PROJECT_DIR:?}"
file=$(jq -r '.tool_input.file_path // empty')

case "$file" in
  "$root"/*) ;;
  *) exit 0 ;;
esac

cd "$root"

case "$file" in
  *.rb | *.rake)
    bin/rubocop -A --force-exclusion "$file" >&2 || exit 2
    ;;
esac

case "$file" in
  *_spec.rb) bundle exec rspec "$file" >&2 || exit 2 ;;
  *.feature) bundle exec cucumber "$file" >&2 || exit 2 ;;
esac

exit 0
