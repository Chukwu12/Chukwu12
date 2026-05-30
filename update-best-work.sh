#!/usr/bin/env bash
set -euo pipefail

USER_NAME="${1:-Chukwu12}"
README="README.md"
TMP_JSON="$(mktemp)"
TMP_BLOCK="$(mktemp)"
TMP_OUT="$(mktemp)"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required." >&2
  exit 1
fi

gh api "users/${USER_NAME}/repos?per_page=100" > "$TMP_JSON"

{
  echo "| Project | Stack | Links |"
  echo "|---|---|---|"
  jq -r --arg u "$USER_NAME" '
    map(select((.fork | not) and .name != $u))
    | sort_by([.stargazers_count, .updated_at])
    | reverse
    | .[0:6]
    | .[]
    | . as $r
    | "| "
      + $r.name
      + " | "
      + ($r.language // "Unknown")
      + " | [Repo]("
      + $r.html_url
      + ")"
      + (if ($r.homepage // "") != "" then " · [Live](" + $r.homepage + ")" else "" end)
      + " |"
  ' "$TMP_JSON"
} > "$TMP_BLOCK"

awk -v blockFile="$TMP_BLOCK" '
  BEGIN {
    while ((getline line < blockFile) > 0) {
      block = block line "\n"
    }
    close(blockFile)
  }
  /<!-- BEST_WORK_START -->/ {
    print
    printf "%s", block
    in_block = 1
    next
  }
  /<!-- BEST_WORK_END -->/ {
    in_block = 0
    print
    next
  }
  !in_block { print }
' "$README" > "$TMP_OUT"

mv "$TMP_OUT" "$README"
rm -f "$TMP_JSON" "$TMP_BLOCK"

echo "Updated Best Work section in ${README} for ${USER_NAME}."
