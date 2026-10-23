#!/usr/bin/env bash
# Author: Magnus Naessan Gaarder
#
# Weekly dotfiles backup, run by systemd/dotfiles-backup.timer.
#
# The backup is GitHub's copy (origin/main): it only moves after a successful push.
# Like an HTTP ETag check, the project's content fingerprint (git tree hash, with
# .gitignore applied) is compared to the backup's; equal means nothing to do.
#
#   exit 0   skipped (unchanged) or backed up
#   exit 75  GitHub unreachable, nothing committed; systemd retries hourly (3x)
#   exit 1   needs a manual fix: check failed, push failed or GitHub has newer
#            commits. Backups pause until you have fixed and pushed it yourself.
#
# Usage: tools/backup.sh [--status]

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-backup"
LAST="$STATE_DIR/last-success" # time, commit and files of the last successful backup
FAILED="$STATE_DIR/failed"     # present while a failure waits for a manual fix
ATTEMPTS="$STATE_DIR/fetch-attempts"
MAX_FETCH_ATTEMPTS=4 # the scheduled run + 3 hourly retries
BRANCH=main
mkdir -p "$STATE_DIR"

notify() {
	command -v notify-send >/dev/null && notify-send -u "${2:-normal}" "Dotfiles backup" "$1"
	echo "$1"
}

ago() {
	local s=$(($(date +%s) - $1))
	if [ "$s" -lt 3600 ]; then echo "$((s / 60)) min ago"
	elif [ "$s" -lt 172800 ]; then echo "$((s / 3600)) h ago"
	else echo "$((s / 86400)) days ago"; fi
}

last_field() { [ -f "$LAST" ] && sed -n "s/^$1=//p" "$LAST"; }

if [ "${1:-}" = "--status" ]; then
	if [ -f "$LAST" ]; then
		echo "Last backup: $(last_field time) ($(ago "$(last_field epoch)")), commit $(last_field commit)"
		last_field files | tr ',' '\n' | sed 's/^/  /'
	else
		echo "No successful backup recorded yet."
	fi
	[ -f "$FAILED" ] && echo "PAUSED, waiting for a manual fix: $(cut -d'|' -f2- "$FAILED" | tr '|' ' ')"
	exit 0
fi

# $1 = kind (check, push, diverged), $2 = message
fail_manual() {
	echo "$1|$(date '+%Y-%m-%d %H:%M')|$2" >"$FAILED"
	notify "$2 Backups are paused until you fix it and push yourself (tools/backup.sh --status)." critical
	exit 1
}

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { notify "$ROOT is not a git repository" critical; exit 1; }
git config core.hooksPath .githooks

# 1. Refresh the local copy of the backup. Offline: commit nothing, let systemd retry.
if ! git fetch -q origin "$BRANCH" 2>/dev/null; then
	n=$(($(cat "$ATTEMPTS" 2>/dev/null || echo 0) + 1))
	echo "$n" >"$ATTEMPTS"
	if [ "$n" -ge "$MAX_FETCH_ATTEMPTS" ]; then
		rm -f "$ATTEMPTS"
		notify "GitHub unreachable after $n tries. Nothing was committed; trying again next week." critical
		exit 1
	fi
	echo "GitHub unreachable (attempt $n of $MAX_FETCH_ATTEMPTS), retrying in an hour."
	exit 75
fi
rm -f "$ATTEMPTS"
BACKUP="origin/$BRANCH"

# 2. A failure waiting for a manual fix. A failed check made no commit, so it is simply
#    checked again below; a failed push or GitHub-has-newer-commits is fixed once this
#    laptop and GitHub agree (everything pulled and pushed).
if [ -f "$FAILED" ]; then
	kind=$(cut -d'|' -f1 "$FAILED")
	if [ "$kind" = "check" ]; then
		rm -f "$FAILED"
		echo "Checking again after the earlier failed integrity check."
	elif git merge-base --is-ancestor HEAD "$BACKUP" && git merge-base --is-ancestor "$BACKUP" HEAD; then
		rm -f "$FAILED"
		echo "Earlier failure was fixed and pushed; resuming backups."
	else
		notify "Still paused: $(cut -d'|' -f3 "$FAILED")" critical
		exit 1
	fi
fi

# 3. Never overwrite changes that are on GitHub but not on this laptop (HTTP 412).
if ! git merge-base --is-ancestor "$BACKUP" HEAD; then
	fail_manual diverged "GitHub has commits this laptop doesn't (pull them first)."
fi

# 4. Fingerprint the project as it would be committed, using a throwaway index so
#    the real one is untouched, and compare it with the backup's fingerprint.
tmp_index=$(mktemp)
trap 'rm -f "$tmp_index"' EXIT
GIT_INDEX_FILE="$tmp_index" git read-tree HEAD
GIT_INDEX_FILE="$tmp_index" git add -A
project_tree=$(GIT_INDEX_FILE="$tmp_index" git write-tree)
backup_tree=$(git rev-parse "$BACKUP^{tree}")

if [ "$project_tree" = "$backup_tree" ]; then
	echo "Project matches the backup ($(git rev-parse --short "$BACKUP")); nothing to do."
	exit 0
fi

mapfile -t changed < <(git diff --name-only "$backup_tree" "$project_tree")

# 5. Different: check, commit (if anything is uncommitted) and push.
if ! tools/check.sh; then
	fail_manual check "Integrity check failed, nothing was committed. Run tools/check.sh in $ROOT to see why."
fi

if [ -n "$(git status --porcelain)" ]; then
	git add -A
	{
		echo "Weekly backup $(date +%Y-%m-%d): ${#changed[@]} file(s) changed"
		echo
		git diff --cached --name-status "$BACKUP" | sed 's/^/  /'
	} | git commit -q -F - || fail_manual push "git commit failed."
fi

if ! git push -q origin "HEAD:$BRANCH"; then
	fail_manual push "Committed $(git rev-parse --short HEAD) but the push failed; the commit stays on this laptop."
fi

previous=$(last_field epoch)
{
	echo "time=$(date '+%Y-%m-%d %H:%M')"
	echo "epoch=$(date +%s)"
	echo "commit=$(git rev-parse --short HEAD)"
	echo "files=$(IFS=,; echo "${changed[*]}")"
} >"$LAST"

shown=$(printf '%s\n' "${changed[@]##*/}" | head -3 | paste -sd, - | sed 's/,/, /g')
[ "${#changed[@]}" -gt 3 ] && shown="$shown, …"
since=""
[ -n "$previous" ] && since=" Previous backup: $(ago "$previous")."
notify "Backed up ${#changed[@]} file(s) ($shown) as $(git rev-parse --short HEAD).$since"
