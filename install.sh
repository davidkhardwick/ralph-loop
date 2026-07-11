#!/usr/bin/env bash
#
# install.sh — install Ralph once so you never copy it into a project again.
#
# Puts two commands on your PATH and installs the Claude Code slash command:
#   • ralph        -> ralph.sh   (the hardened loop)
#   • ralph-init   -> ralph-init (the project scaffolder)
#   • /ralph-init  -> ~/.claude/commands/ralph-init.md  (interactive planner)
#
# By default it SYMLINKS back to this repo, so `git pull` updates your tools.
# Pass --copy to install standalone copies instead (repo can then be moved/deleted).
#
# Usage:
#   ./install.sh            # symlink (recommended)
#   ./install.sh --copy     # copy instead of symlink
#
# Override locations with env vars:
#   RALPH_BIN_DIR (default ~/.local/bin)   RALPH_CMD_DIR (default ~/.claude/commands)

set -euo pipefail

mode="link"
[ "${1:-}" = "--copy" ] && mode="copy"

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin_dir="${RALPH_BIN_DIR:-$HOME/.local/bin}"
cmd_dir="${RALPH_CMD_DIR:-$HOME/.claude/commands}"

mkdir -p "$bin_dir" "$cmd_dir"

install_one() {  # install_one <src> <dest>
  local src="$1" dest="$2"
  [ -e "$src" ] || { echo "ERROR: missing $src" >&2; exit 1; }
  if [ "$mode" = "copy" ]; then
    cp "$src" "$dest"
  else
    ln -sfn "$src" "$dest"
  fi
  printf '  %-4s  %s -> %s\n' "$mode" "$dest" "$src"
}

echo "Installing Ralph from: $repo_dir  (mode: $mode)"
install_one "$repo_dir/ralph.sh"                        "$bin_dir/ralph"
install_one "$repo_dir/ralph-init"                      "$bin_dir/ralph-init"
install_one "$repo_dir/.claude/commands/ralph-init.md"  "$cmd_dir/ralph-init.md"
chmod +x "$bin_dir/ralph" "$bin_dir/ralph-init" 2>/dev/null || true

echo
case ":$PATH:" in
  *":$bin_dir:"*)
    echo "✔ $bin_dir is already on your PATH."
    ;;
  *)
    printf '⚠ %s is not on your PATH. Add this to your shell profile (e.g. ~/.zshrc):\n\n' "$bin_dir"
    printf '    export PATH="%s:$PATH"\n\n' "$bin_dir"
    echo "  then restart your shell (or: source ~/.zshrc)"
    ;;
esac

cat <<'EOF'

Done. From ANY project directory:
  ralph-init      scaffold spec.md / implementation_plan.md / prompt.md templates
  /ralph-init     (in Claude Code) have Claude interview you and write those files
  ralph           run the loop

To uninstall: rm the symlinks/copies from the two locations printed above.
EOF
