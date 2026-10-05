#!/usr/bin/env bash
# what-i-use.sh — find the commands you ACTUALLY type, ranked, and map
# them back to the pacman package that provides them, so you can migrate
# real usage to Nix instead of eyeballing `pacman -Qq` (the whole system).
#
# Usage:  bash tools/what-i-use.sh            # bash history (default)
#         bash tools/what-i-use.sh ~/.zsh_history   # zsh or other path
#
# Not wired into the flake — it's a bootstrap tool, lives in the repo so
# both machines get it on clone.

set -u
HIST="${1:-$HOME/.bash_history}"
if [[ ! -r "$HIST" ]]; then
  echo "no history at $HIST — pass a path, e.g. bash tools/what-i-use.sh ~/.zsh_history" >&2
  exit 1
fi

echo "real commands you type, ranked -> owning package (from $HIST)"
echo "  count  command      package"
echo "  -----  -----------  -----------------------------"

# 1) first token per line (strip sudo), drop shell noise, count, sort desc
awk '{ if ($1=="sudo" && NF>1) $1=$2; print $1 }' "$HIST" |
  grep -vE '^(cd|ll|la|ls|clear|sudo|exit|history|man|echo|source|\.)$' |
  sort | uniq -c | sort -rn |
  while read -r cnt cmd; do

    # keep only real binaries; skip builtins, aliases, functions, keywords
    t=$(type -t "$cmd" 2>/dev/null || true)
    case "$t" in
    file) path=$(command -v "$cmd" 2>/dev/null) ;;
    *) continue ;;
    esac

    # skip non-package stuff: your own scripts, nix-managed, manual installs
    case "$path" in
    "$HOME"/*) continue ;;    # your scripts -> home.file, not home.packages
    /nix/store/*) continue ;; # already Nix-managed
    /usr/local/*) continue ;; # manual tarball/script installs
    esac

    pkg=$(pacman -Qqo "$path" 2>/dev/null || echo "?")
    printf "%6s  %-11s %s\n" "$cnt" "$cmd" "$pkg"
  done
