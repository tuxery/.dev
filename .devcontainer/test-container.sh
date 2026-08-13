#!/usr/bin/env bash
# test-container.sh — Verifies that the devcontainer environment is complete.
# Run INSIDE the container after `postCreateCommand`.
# Usage: bash .devcontainer/test-container.sh
set -uo pipefail

PASS=0
FAIL=0
WARN=0

ok()   { echo "  ✓ $1"; ((PASS++)); }
fail() { echo "  ✗ $1"; ((FAIL++)); }
warn() { echo "  ⚠ $1"; ((WARN++)); }

check_cmd() {
  local cmd=$1 label=${2:-$1}
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$label — $(command -v "$cmd")"
  else
    fail "$label — not found"
  fi
}

check_version() {
  local cmd=$1 args=${2:---version} label=${3:-$1}
  if out=$("$cmd" $args 2>&1 | head -1); then
    ok "$label — $out"
  else
    fail "$label — failed ($out)"
  fi
}

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Tuxery devcontainer — environment test"
echo "═══════════════════════════════════════════════════"

# ── GitHub / git ───────────────────────────────────────────────────────────────
echo ""
echo "── GitHub & git ──"

if gh auth status >/dev/null 2>&1; then
  account=$(gh api user --jq '.login' 2>/dev/null || echo "unknown")
  ok "gh CLI authenticated — account: $account"
else
  fail "gh CLI not authenticated (GH_TOKEN missing or invalid)"
fi

if git ls-remote "https://github.com/tuxery/.github.git" HEAD >/dev/null 2>&1; then
  ok "git — read access to tuxery/.github"
else
  warn "git — HTTPS access failed (SSH may still work)"
fi

check_cmd git "git"

# ── JavaScript / Qwik toolchain ─────────────────────────────────────────────────
echo ""
echo "── JavaScript toolchain ──"

check_version node "--version" "node"
check_cmd pnpm "pnpm"
check_cmd nub "nub (pnpm accelerator)"
check_cmd nubx "nubx (npx accelerator)"

# ── Critical environment variables ────────────────────────────────────────────
echo ""
echo "── Environment ──"

if [ -n "${GH_TOKEN:-}" ]; then
  ok "GH_TOKEN — present"
else
  fail "GH_TOKEN — missing (export GH_TOKEN_FOR_TUXERY on the host before reopening)"
fi

# ── Workspace repos ───────────────────────────────────────────────────────────
echo ""
echo "── Workspace repos ──"

if [ -w /workspaces ]; then
  ok "/workspaces — writable by $(whoami) (sibling repos can be cloned)"
else
  fail "/workspaces — not writable by $(whoami) (sibling clones will fail with 'Permission denied'; re-run setup-container.sh)"
fi

for repo in .dev .github app; do
  if [ -d "/workspaces/$repo" ]; then
    ok "/workspaces/$repo"
  else
    warn "/workspaces/$repo — not present (normal if not cloned yet)"
  fi
done

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════"
printf "  Result: %d ✓  %d ⚠  %d ✗\n" "$PASS" "$WARN" "$FAIL"
echo "═══════════════════════════════════════════════════"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "  Critical items are missing."
  echo "  Rebuild the container or re-run setup-container.sh"
  exit 1
fi
exit 0
