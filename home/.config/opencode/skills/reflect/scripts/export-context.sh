#!/usr/bin/env bash
# Export an opencode session transcript plus navigation aids for the reflect skill.
# Usage: export-context.sh [sessionID]   (defaults to the latest session for the cwd's project)
set -euo pipefail

SESSION_ID="${1:-}"
if [[ -z "$SESSION_ID" ]]; then
  SESSION_ID=$(opencode session list 2>/dev/null | awk '/^ses_/ {print $1; exit}')
fi
if [[ -z "$SESSION_ID" ]]; then
  echo "error: no session found; pass a session ID explicitly" >&2
  exit 1
fi

OUTDIR=$(mktemp -d "/tmp/reflect-${SESSION_ID}.XXXXXX")
EXPORT="$OUTDIR/export.json"
MAP="$OUTDIR/map.txt"
DCP="$OUTDIR/dcp.json"
DCP_STATE="$HOME/.local/share/opencode/storage/plugin/dcp/${SESSION_ID}.json"

opencode export "$SESSION_ID" 2>/dev/null > "$EXPORT" || true
if [[ ! -s "$EXPORT" ]] || ! jq -e '.messages | length > 0' "$EXPORT" >/dev/null 2>&1; then
  echo "error: export failed for session $SESSION_ID" >&2
  exit 1
fi

# One line per message: id, role, part inventory with short previews.
jq -r '
  .messages[] |
  "[" + .info.id + "] " + .info.role +
  ([.parts[] | select(.type != "step-start" and .type != "step-finish") |
    if .type == "tool" then "tool:" + .tool + "(" + (.state.status // "") + ") " + ((.state.title // "") | gsub("\n"; " ") | .[0:80])
    elif .type == "text" then "text:" + ((.text // "") | gsub("\n"; " ") | .[0:120])
    else .type
    end
  ] as $parts | if ($parts | length) > 0 then " | " + ($parts | join(" | ")) else "" end)
' "$EXPORT" > "$MAP"

if [[ -f "$DCP_STATE" ]]; then
  jq '{
    totalPruneTokens: .stats.totalPruneTokens,
    compressions: [.prune.messages.blocksById[] | {
      blockId, topic, summary, compressedTokens, summaryTokens, active, deactivatedByUser, createdAt
    }]
  }' "$DCP_STATE" > "$DCP"
else
  echo '{}' > "$DCP"
fi

DOTFILES=$(dirname "$(readlink "$HOME/Taskfile.yaml")")

echo "session:  $SESSION_ID"
echo "export:   $EXPORT ($(wc -c < "$EXPORT" | tr -d ' ') bytes, $(jq '.messages | length' "$EXPORT") messages)"
echo "map:      $MAP ($(wc -l < "$MAP" | tr -d ' ') lines)"
echo "dcp:      $DCP ($(jq -r '.totalPruneTokens // 0' "$DCP") pruned tokens)"
echo "dotfiles: $DOTFILES"
