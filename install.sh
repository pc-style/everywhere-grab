#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

MIN_NODE_MAJOR=22

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: $1 is required but not installed." >&2
    exit 1
  fi
}

require_node_version() {
  require_command node
  local node_major
  node_major="$(node -p "process.versions.node.split('.')[0]")"
  if [[ "$node_major" -lt "$MIN_NODE_MAJOR" ]]; then
    echo "Error: Node.js ${MIN_NODE_MAJOR}+ is required (found $(node -v))." >&2
    exit 1
  fi
}

ensure_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    return
  fi
  if command -v corepack >/dev/null 2>&1; then
    echo "→ Enabling pnpm via corepack..."
    corepack enable
    corepack prepare pnpm@10.24.0 --activate
    return
  fi
  echo "Error: pnpm is required. Install it or enable corepack." >&2
  exit 1
}

require_node_version
ensure_pnpm

echo "→ Installing dependencies..."
pnpm install

echo "→ Building packages..."
pnpm build

REACT_GRAB_PKG="${ROOT}/packages/react-grab"
GRAB_CLI_PKG="${ROOT}/packages/grab"
PKG_SPEC="file:${REACT_GRAB_PKG}"

echo "→ Linking grab CLI globally..."
(
  cd "$GRAB_CLI_PKG"
  pnpm link --global
)

ENV_FILE="${ROOT}/.grab-fork.env"
cat >"$ENV_FILE" <<EOF
# Source in your shell: source "${ENV_FILE}"
export GRAB_PKG="${PKG_SPEC}"
EOF

echo ""
echo "Fork installed locally (nothing published to npm)."
echo ""
echo "Add to your shell profile or run once per session:"
echo "  source \"${ENV_FILE}\""
echo ""
echo "Then in any project:"
echo "  grab init"
echo ""
echo "Or pass the local package explicitly:"
echo "  grab init --pkg \"${PKG_SPEC}\""
echo ""
echo "Manual install in a project (no grab init):"
echo "  pnpm add -D \"${PKG_SPEC}\""
