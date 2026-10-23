#!/usr/bin/env bash
# Author: Magnus Naessan Gaarder
#
# Weekly dotfiles backup, run by systemd/dotfiles-backup.timer.
# Commits whatever changed in the repo and pushes it, but only if tools/check.sh
# passes. Failures leave everything uncommitted and send a desktop notification.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

notify() {
	command -v notify-send >/dev/null && notify-send -u "${2:-normal}" "Dotfiles backup" "$1"
	echo "$1"
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { notify "$ROOT is not a git repository" critical; exit 1; }
git config core.hooksPath .githooks

if [ -z "$(git status --porcelain)" ]; then
	echo "Nothing changed since the last backup."
	exit 0
fi

if ! tools/check.sh; then
	notify "Integrity check failed, nothing was committed. Run tools/check.sh in $ROOT to see why." critical
	exit 1
fi

git add -A
git commit -q -m "Automatic weekly backup $(date +%Y-%m-%d)" || { notify "git commit failed" critical; exit 1; }

if git push -q; then
	notify "Backed up and pushed $(git rev-parse --short HEAD)."
else
	notify "Committed $(git rev-parse --short HEAD) but the push failed (offline or not logged in to gh?). It will go up with the next push." critical
	exit 1
fi
