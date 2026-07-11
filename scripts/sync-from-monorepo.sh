#!/usr/bin/env bash
#
# Sync this public distribution repo from the canonical plugin in the private
# izap monorepo. The monorepo's `izap-plugin/` is the source of truth for the
# plugin body (skill, commands, examples, MCP config); this repo re-publishes it
# under `izap/` with an MIT license plus the Cursor and Codex variants.
#
# Usage:
#   scripts/sync-from-monorepo.sh <path-to-monorepo>/izap-plugin
#
# Then review the printed diff, hand-update the Cursor/Codex variants and this
# repo's README/marketplace if the tool surface or version changed, commit, and
# open a PR.
#
# Requires: rsync, jq.
set -euo pipefail

SRC="${1:?usage: scripts/sync-from-monorepo.sh <path-to-monorepo>/izap-plugin}"
SRC="${SRC%/}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$REPO/izap"

[ -f "$SRC/.claude-plugin/plugin.json" ] || {
  echo "error: $SRC does not look like the monorepo izap-plugin/ dir" >&2
  exit 1
}

command -v jq >/dev/null    || { echo "error: jq is required" >&2; exit 1; }
command -v rsync >/dev/null || { echo "error: rsync is required" >&2; exit 1; }

# Byte-identical plugin body. README.md is intentionally NOT synced — this repo
# keeps its own (public install URL); the monorepo keeps its own.
for dir in skills commands examples; do
  rsync -a --delete "$SRC/$dir/" "$DEST/$dir/"
done
cp "$SRC/.mcp.json" "$DEST/.mcp.json"

# plugin.json: mirror the manifest verbatim but publish under MIT. Use a targeted
# substitution (not jq) so the file keeps its hand-written formatting and syncs
# don't churn the diff.
sed 's/"license": "UNLICENSED"/"license": "MIT"/' \
  "$SRC/.claude-plugin/plugin.json" > "$DEST/.claude-plugin/plugin.json"

# The marketplace entry version and the plugin version must match, since
# plugin.json's version pins the install cache. Warn (don't rewrite) so this
# repo's hand-maintained marketplace.json stays formatting-stable.
VER="$(jq -r '.version' "$SRC/.claude-plugin/plugin.json")"
MKT_VER="$(jq -r '.plugins[] | select(.name == "izap") | .version' "$REPO/.claude-plugin/marketplace.json")"

echo "Synced plugin body from: $SRC"
echo "Plugin version: $VER"
if [ "$VER" != "$MKT_VER" ]; then
  echo "⚠ marketplace.json entry version ($MKT_VER) != plugin version ($VER) — bump it in .claude-plugin/marketplace.json"
fi
echo
echo "Now review — these are hand-maintained derivations of the skill and are NOT synced:"
echo "  • .cursor/rules/izap-platform.mdc   (Cursor variant of the skill summary)"
echo "  • codex/config.toml                 (Codex MCP wiring)"
echo "  • README.md                         (public install instructions)"
echo "If the tool catalog or MCP surface changed, update the summary lines there to match."
echo
git -C "$REPO" status --short
