#!/bin/bash
# Surface a one-line notice at session start when the jot or pencil backlog has grown past its threshold.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SETTINGS_FILE="$PROJECT_DIR/.claude/jotbook.local.md"

JOTS_DIR="docs/jotbook/_jots"
PENCILS_DIR="docs/jotbook/_pencils"
JOTS_THRESHOLD=8
PENCILS_THRESHOLD=3

if [[ -f "$SETTINGS_FILE" ]]; then
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SETTINGS_FILE")

  JOTS_OVERRIDE=$(echo "$FRONTMATTER" | grep '^jots_dir:' | sed 's/jots_dir: *//' | sed 's/^"\(.*\)"$/\1/' | sed 's:/$::' || true)
  PENCILS_OVERRIDE=$(echo "$FRONTMATTER" | grep '^pencils_dir:' | sed 's/pencils_dir: *//' | sed 's/^"\(.*\)"$/\1/' | sed 's:/$::' || true)
  JOTS_THRESH_OVERRIDE=$(echo "$FRONTMATTER" | grep '^backlog_threshold:' | sed 's/backlog_threshold: *//' | tr -d ' ' || true)
  PENCILS_THRESH_OVERRIDE=$(echo "$FRONTMATTER" | grep '^pencils_threshold:' | sed 's/pencils_threshold: *//' | tr -d ' ' || true)

  [[ -n "${JOTS_OVERRIDE:-}" ]] && JOTS_DIR="$JOTS_OVERRIDE"
  [[ -n "${PENCILS_OVERRIDE:-}" ]] && PENCILS_DIR="$PENCILS_OVERRIDE"
  [[ -n "${JOTS_THRESH_OVERRIDE:-}" && "$JOTS_THRESH_OVERRIDE" =~ ^[0-9]+$ ]] && JOTS_THRESHOLD="$JOTS_THRESH_OVERRIDE"
  [[ -n "${PENCILS_THRESH_OVERRIDE:-}" && "$PENCILS_THRESH_OVERRIDE" =~ ^[0-9]+$ ]] && PENCILS_THRESHOLD="$PENCILS_THRESH_OVERRIDE"
fi

JOTS_FULL_DIR="$PROJECT_DIR/$JOTS_DIR"
PENCILS_FULL_DIR="$PROJECT_DIR/$PENCILS_DIR"

JOTS_COUNT=0
PENCILS_COUNT=0
if [[ -d "$JOTS_FULL_DIR" ]]; then
  JOTS_COUNT=$(find "$JOTS_FULL_DIR" -maxdepth 1 -name '*.md' ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
fi
if [[ -d "$PENCILS_FULL_DIR" ]]; then
  PENCILS_COUNT=$(find "$PENCILS_FULL_DIR" -maxdepth 1 \( -name '*.md' -o -name '*.html' \) ! -name 'README.md' 2>/dev/null | wc -l | tr -d ' ')
fi

JOTS_OVER=0
PENCILS_OVER=0
[[ "$JOTS_COUNT" -ge "$JOTS_THRESHOLD" ]] && JOTS_OVER=1
[[ "$PENCILS_COUNT" -ge "$PENCILS_THRESHOLD" ]] && PENCILS_OVER=1

if [[ "$JOTS_OVER" == "1" && "$PENCILS_OVER" == "1" ]]; then
  MESSAGE="Jotbook: $JOTS_COUNT jots staged (threshold $JOTS_THRESHOLD), $PENCILS_COUNT pencils awaiting review (threshold $PENCILS_THRESHOLD). Run /jotbook-ink to curate jots, /jot review pencils for pencils."
elif [[ "$JOTS_OVER" == "1" ]]; then
  MESSAGE="Jotbook: $JOTS_COUNT jots staged (threshold $JOTS_THRESHOLD). Run /jotbook-ink to curate."
elif [[ "$PENCILS_OVER" == "1" ]]; then
  MESSAGE="Jotbook: $PENCILS_COUNT pencils awaiting review (threshold $PENCILS_THRESHOLD). Run /jot review pencils to evaluate."
else
  exit 0
fi

cat <<EOF
{
  "continue": true,
  "systemMessage": "$MESSAGE"
}
EOF

exit 0
