#!/usr/bin/env bash
set -euo pipefail

GRAB_INSTALL_REPO="${GRAB_INSTALL_REPO:-https://github.com/pc-style/everywhere-grab.git}"
GRAB_INSTALL_BRANCH="${GRAB_INSTALL_BRANCH:-main}"
GRAB_FORK_DIR="${GRAB_FORK_DIR:-${HOME}/.everywhere-grab}"
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

resolve_repo_root() {
  local script_path="${BASH_SOURCE[0]:-}"
  if [[ -n "$script_path" && -f "$script_path" ]]; then
    local candidate_root
    candidate_root="$(cd "$(dirname "$script_path")" && pwd)"
    if [[ -f "${candidate_root}/pnpm-workspace.yaml" ]]; then
      echo "$candidate_root"
      return
    fi
  fi
  echo ""
}

ensure_fork_clone() {
  if [[ -d "${GRAB_FORK_DIR}/.git" ]]; then
    echo "→ Updating fork at ${GRAB_FORK_DIR}..."
    git -C "$GRAB_FORK_DIR" fetch --depth 1 origin "$GRAB_INSTALL_BRANCH"
    git -C "$GRAB_FORK_DIR" checkout "$GRAB_INSTALL_BRANCH"
    git -C "$GRAB_FORK_DIR" reset --hard "origin/${GRAB_INSTALL_BRANCH}"
    return
  fi

  require_command git
  echo "→ Cloning fork to ${GRAB_FORK_DIR}..."
  git clone --depth 1 --branch "$GRAB_INSTALL_BRANCH" "$GRAB_INSTALL_REPO" "$GRAB_FORK_DIR"
}

run_install() {
  local root="$1"
  cd "$root"

  require_node_version
  ensure_pnpm

  echo "→ Installing dependencies..."
  pnpm install

  echo "→ Building packages..."
  pnpm build

  local react_grab_pkg="${root}/packages/react-grab"
  local grab_cli_pkg="${root}/packages/grab"
  local pkg_spec="file:${react_grab_pkg}"

  echo "→ Linking grab CLI globally..."
  (
    cd "$grab_cli_pkg"
    pnpm link --global
  )

  local env_file="${root}/.grab-fork.env"
  cat >"$env_file" <<EOF
# Source in your shell: source "${env_file}"
export GRAB_PKG="${pkg_spec}"
EOF

  echo ""
  echo "Fork installed locally (nothing published to npm)."
  echo ""
  echo "Add to your shell profile or run once per session:"
  echo "  source \"${env_file}\""
  echo ""
  echo "Then in any project:"
  echo "  grab init"
  echo ""
  echo "Or pass the local package explicitly:"
  echo "  grab init --pkg \"${pkg_spec}\""
  echo ""
  echo "Manual install in a project (no grab init):"
  echo "  pnpm add -D \"${pkg_spec}\""
}

ROOT="$(resolve_repo_root)"
if [[ -z "$ROOT" ]]; then
  ensure_fork_clone
  ROOT="$GRAB_FORK_DIR"
fi

run_install "$ROOT"
