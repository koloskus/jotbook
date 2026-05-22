#!/bin/bash
# Surface a one-line notice at session start when the jot backlog has grown past the threshold.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SETTINGS_FILE="$PROJECT_DIR/.claude/jotbook.local.md"

JOTS_DIR="docs/jotbook/_candidates"
THRESHOLD=8

if [[ -f "$SETTINGS_FILE" ]]; then
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SETTINGS_FILE")

  JOTS_OVERRIDE=$(echo "$FRONTMATTER" | grep '^jots_dir:' | sed 's/jots_dir: *//' | sed 's/^"\(.*\)"$/\1/' | sed 's:/$::' || true)
  THRESH_OVERRIDE=$(echo "$FRONTMATTER" | grep '^backlog_threshold:' | sed 's/backlog_threshold: *//' | tr -d ' ' || true)

  [[ -n "${JOTS_OVERRIDE:-}" ]] && JOTS_DIR="$JOTS_OVERRIDE"
  [[ -n "${THRESH_OVERRIDE:-}" && "$THRESH_OVERRIDE" =~ ^[0-9]+$ ]] && THRESHOLD="$THRESH_OVERRIDE"
fi

FULL_DIR="$PROJECT_DIR/$JOTS_DIR"

if [[ ! -d "$FULL_DIR" ]]; then
  exit 0
fi

COUNT=$(find "$FULL_DIR" -maxdepth 1 -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')

if [[ "$COUNT" -ge "$THRESHOLD" ]]; then
  cat <<EOF
{
  "continue": true,
  "systemMessage": "Jotbook: $COUNT jots staged (threshold $THRESHOLD). Run /jotbook to curate."
}
EOF
fi

exit 0
