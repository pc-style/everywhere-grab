#!/usr/bin/env bash
set -euo pipefail

GRAB_INSTALL_REPO="${GRAB_INSTALL_REPO:-https://github.com/pc-style/everywhere-grab.git}"
GRAB_INSTALL_BRANCH="${GRAB_INSTALL_BRANCH:-main}"
GRAB_FORK_DIR="${GRAB_FORK_DIR:-${HOME}/.everywhere-grab}"
GRAB_SHELL_MARKER="# react-grab fork (everywhere-grab install.sh)"
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

is_interactive_install() {
  [[ -t 0 ]] && [[ -z "${GRAB_INSTALL_YES:-}" ]] && [[ -z "${GRAB_INSTALL_NO_SHELL_RC:-}" ]] && [[ -z "${CI:-}" ]]
}

prompt_yes_no() {
  local prompt_message="$1"
  local reply=""
  read -r -p "${prompt_message} [y/N] " reply </dev/tty || return 1
  case "${reply}" in
    [yY] | [yY][eE][sS]) return 0 ;;
    *) return 1 ;;
  esac
}

detect_shell_rc_file() {
  local shell_path="${SHELL:-}"
  local shell_name="${shell_path##*/}"

  case "$shell_name" in
    zsh)
      echo "${ZDOTDIR:-${HOME}}/.zshrc"
      ;;
    bash)
      if [[ -f "${HOME}/.bashrc" ]]; then
        echo "${HOME}/.bashrc"
      elif [[ -f "${HOME}/.bash_profile" ]]; then
        echo "${HOME}/.bash_profile"
      else
        echo "${HOME}/.bashrc"
      fi
      ;;
    fish)
      echo "${HOME}/.config/fish/config.fish"
      ;;
    *)
      if [[ -f "${HOME}/.profile" ]]; then
        echo "${HOME}/.profile"
      else
        echo "${HOME}/.bashrc"
      fi
      ;;
  esac
}

shell_rc_has_grab_fork_block() {
  local rc_file="$1"
  [[ -f "$rc_file" ]] && grep -Fq "$GRAB_SHELL_MARKER" "$rc_file"
}

append_grab_fork_to_shell_rc() {
  local rc_file="$1"
  local env_file="$2"

  if shell_rc_has_grab_fork_block "$rc_file"; then
    echo "→ Shell profile already loads the grab fork (${rc_file})."
    return
  fi

  local rc_directory
  rc_directory="$(dirname "$rc_file")"
  mkdir -p "$rc_directory"

  {
    echo ""
    echo "$GRAB_SHELL_MARKER"
    echo "[ -f \"${env_file}\" ] && . \"${env_file}\""
  } >>"$rc_file"

  echo "→ Added grab fork to ${rc_file}"
}

offer_shell_profile_setup() {
  local env_file="$1"
  local rc_file
  rc_file="$(detect_shell_rc_file)"

  if [[ "${GRAB_INSTALL_YES:-}" == "1" ]]; then
    append_grab_fork_to_shell_rc "$rc_file" "$env_file"
    return
  fi

  if [[ "${GRAB_INSTALL_NO_SHELL_RC:-}" == "1" ]]; then
    return
  fi

  if ! is_interactive_install; then
    echo ""
    echo "Tip: add this to ${rc_file} to load GRAB_PKG in new shells:"
    echo "  [ -f \"${env_file}\" ] && . \"${env_file}\""
    return
  fi

  echo ""
  if prompt_yes_no "Add grab fork to ${rc_file} (so you don't need to source it each time)?"; then
    append_grab_fork_to_shell_rc "$rc_file" "$env_file"
    echo "  Open a new terminal or run: source \"${rc_file}\""
  else
    echo "Skipped shell profile. Run once per session:"
    echo "  source \"${env_file}\""
  fi
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

  offer_shell_profile_setup "$env_file"

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
