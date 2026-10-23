#!/usr/bin/env bash
# Author: Magnus Naessan Gaarder
#
# Integrity check for the dotfiles repo: secrets (.env files, tokens, plain-text
# passwords, gitleaks over files and history) and syntax. Runs from the pre-push hook, the weekly
# backup (tools/backup.sh) and GitHub Actions; any failure blocks the push.
#
# Usage: tools/check.sh [--full]
#   --full  also start Neovim headless against the repo config (needs plugins installed)

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1

FULL=0
[ "${1:-}" = "--full" ] && FULL=1

fail=0
err() { printf '  FAIL %s\n' "$*"; fail=1; }
section() { printf '== %s\n' "$*"; }

# Files that would end up in a commit: tracked plus untracked-but-not-ignored.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	mapfile -t FILES < <(git ls-files -co --exclude-standard)
else
	mapfile -t FILES < <(find . -type f -not -path './.git/*' | sed 's|^\./||')
fi

by_ext() { printf '%s\n' "${FILES[@]}" | grep -E "$1" || true; }

section "secrets"
for f in "${FILES[@]}"; do
	case "$(basename "$f")" in
	.env.example) ;;
	.env | .env.* | *.pem | *.key | id_rsa* | id_ed25519*) err "$f must never be committed" ;;
	esac
done
# Real-looking credentials: GitHub/OpenAI/Anthropic/AWS/Slack tokens, private keys,
# or an OPENWEATHER_KEY with a value outside .env.example.
secret_re='(gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|sk-(ant-)?[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|OPENWEATHER_KEY=[A-Za-z0-9]{8,})'
# A password/key/token written out in plain text, e.g. `password = hunter2secret`.
# Values that are variables ($X, ${X}, $(...)) or shorter than 8 characters are ignored.
plain_re='(^|[^A-Za-z0-9_])(password|passwd|passphrase|secret|token|api[_-]?key|apikey|client[_-]?secret|auth[_-]?key)["'"'"']?[[:space:]]*[:=][[:space:]]*["'"'"']?[^"'"'"'[:space:]$({<]{8,}'
for f in "${FILES[@]}"; do
	[ -f "$f" ] || continue
	[ "$(basename "$f")" = "check.sh" ] && continue
	if grep -IqE "$secret_re" "$f" 2>/dev/null; then
		err "$f looks like it contains a secret"
	fi
	[[ "$f" == *.env.example ]] && continue
	grep -nIiE "$plain_re" "$f" 2>/dev/null | cut -d: -f1 | while read -r line; do
		printf '  FAIL %s:%s looks like a plain-text password or key\n' "$f" "$line"
	done | grep . && fail=1
done

section "gitleaks"
if command -v gitleaks >/dev/null; then
	# Scan exactly the files that would be committed (not gitignored ones like .env),
	# then the whole git history, so a secret committed once and deleted later is caught.
	tmp=$(mktemp -d)
	trap 'rm -rf "$tmp"' EXIT
	printf '%s\n' "${FILES[@]}" | while read -r f; do [ -f "$f" ] && echo "$f"; done |
		tar -cf - -T - | tar -xf - -C "$tmp"
	gitleaks dir "$tmp" --no-banner --redact -v --exit-code 1 >"$tmp.log" 2>&1 ||
		{ sed "s|$tmp/||; s/^/  /" "$tmp.log" | tail -30; err "gitleaks found secrets in the files"; }
	if git rev-parse --verify -q HEAD >/dev/null 2>&1; then
		gitleaks git . --no-banner --redact -v --exit-code 1 >"$tmp.log" 2>&1 ||
			{ sed 's/^/  /' "$tmp.log" | tail -30; err "gitleaks found secrets in the git history"; }
	fi
	rm -f "$tmp.log"
else
	err "gitleaks is not installed (sudo pacman -S gitleaks)"
fi

section "file sizes"
for f in "${FILES[@]}"; do
	[ -f "$f" ] || continue
	size=$(stat -c %s "$f")
	if [ "$size" -gt $((20 * 1024 * 1024)) ]; then
		err "$f is $((size / 1024 / 1024)) MB (limit 20 MB)"
	fi
done

section "shell syntax"
while read -r f; do
	[ -n "$f" ] || continue
	bash -n "$f" 2>&1 | sed 's/^/  /' | grep . && err "$f"
done < <(
	by_ext '\.sh$'
	for f in "${FILES[@]}"; do
		[ -f "$f" ] && [[ "$f" != *.* ]] && head -c 64 "$f" 2>/dev/null | grep -qE '^#!.*\b(ba)?sh\b' && echo "$f"
	done
)
if command -v shellcheck >/dev/null; then
	by_ext '\.sh$' | xargs -r -d '\n' shellcheck -S error || err "shellcheck reported errors"
fi

section "python syntax"
while read -r f; do
	[ -n "$f" ] || continue
	python3 -c 'import ast, sys; ast.parse(open(sys.argv[1]).read(), sys.argv[1])' "$f" || err "$f"
done < <(by_ext '\.py$')

section "lua syntax"
LUAC=$(command -v luac || command -v luac5.4 || true)
if [ -n "$LUAC" ]; then
	while read -r f; do
		[ -n "$f" ] || continue
		"$LUAC" -p "$f" || err "$f"
	done < <(by_ext '\.lua$')
else
	err "luac not found"
fi

section "json syntax"
while read -r f; do
	[ -n "$f" ] || continue
	jq empty "$f" 2>/dev/null || err "$f is not valid JSON"
done < <(by_ext '\.json$')

if [ "$FULL" = 1 ] && command -v nvim >/dev/null; then
	section "neovim config loads"
	out=$(XDG_CONFIG_HOME="$ROOT/dotfiles/dot-config" timeout 60 nvim --headless +qa 2>&1)
	if printf '%s' "$out" | grep -qiE 'error|E[0-9]{3,4}:'; then
		printf '%s\n' "$out" | sed 's/^/  /' | head -20
		err "nvim reported errors"
	fi
fi

if [ "$fail" -ne 0 ]; then
	echo "check.sh: FAILED"
	exit 1
fi
echo "check.sh: all checks passed"
