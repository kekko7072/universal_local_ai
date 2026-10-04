#!/usr/bin/env bash
# Verifies that every submodule pin is a commit that exists upstream and is
# reachable from that repository's default branch (i.e. merged, not a
# feature-branch commit that a squash merge could make unreachable).
#
# Usage: check-submodule-pins.sh [--strict]
#   --strict  fail on unmerged pins; otherwise only warn.
set -euo pipefail

strict=false
[[ "${1:-}" == "--strict" ]] && strict=true
status=0

while read -r _ path; do
  url=$(git config --file .gitmodules --get "submodule.$path.url")
  pin=$(git ls-tree HEAD "$path" | awk '{print $3}')
  default=$(git ls-remote --symref "$url" HEAD | awk '/^ref:/ {sub("refs/heads/", "", $2); print $2}')
  work=$(mktemp -d)
  git -C "$work" init -q
  git -C "$work" fetch -q --filter=blob:none "$url" "$default"
  default_sha=$(git -C "$work" rev-parse FETCH_HEAD)

  if ! git -C "$work" fetch -q --filter=blob:none "$url" "$pin" 2>/dev/null; then
    echo "::error title=Submodule pin missing::$path pins $pin, which does not exist in $url"
    status=1
  elif git -C "$work" merge-base --is-ancestor "$pin" "$default_sha"; then
    behind=$(git -C "$work" rev-list --count "$pin..$default_sha")
    echo "ok   $path @ ${pin:0:7} is on $default ($behind commit(s) behind)"
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
      echo "| \`$path\` | \`${pin:0:7}\` | on \`$default\` | $behind behind |" >> "$GITHUB_STEP_SUMMARY"
    fi
  else
    level=warning
    $strict && { level=error; status=1; }
    echo "::$level title=Unmerged submodule pin::$path pins ${pin:0:7}, which is not on $default yet. Merge it upstream, then re-pin to $default."
    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
      echo "| \`$path\` | \`${pin:0:7}\` | **not on \`$default\`** | — |" >> "$GITHUB_STEP_SUMMARY"
    fi
  fi
  rm -rf "$work"
done < <(git config --file .gitmodules --get-regexp '^submodule\..*\.path$')

exit "$status"
