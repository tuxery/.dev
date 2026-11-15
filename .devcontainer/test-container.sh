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

if command -v turso >/dev/null 2>&1 || [ -x "$HOME/.turso/turso" ]; then
  ok "turso CLI — local libSQL dev server for app/catalog"
else
  fail "turso CLI — not found (re-run setup-container.sh, or: curl -sSfL https://get.tur.so/install.sh | bash)"
fi

# ── Critical environment variables ────────────────────────────────────────────
echo ""
echo "── Environment ──"

if [ -n "${GH_TOKEN:-}" ]; then
  ok "GH_TOKEN — present"
else
  fail "GH_TOKEN — missing (not loaded from OpenBao, see openbao-env status)"
fi

if [ -n "${GEMINI_API_KEY:-}" ]; then
  ok "GEMINI_API_KEY — present"
else
  warn "GEMINI_API_KEY — missing (not loaded from OpenBao, see openbao-env status; only needed for catalog's pnpm classify-llm)"
fi

if [ -n "${GROQ_API_KEY:-}" ]; then
  ok "GROQ_API_KEY — present"
else
  warn "GROQ_API_KEY — missing (not loaded from OpenBao, see openbao-env status; only needed for catalog's LLM classification)"
fi

if [ -n "${TURSO_API_TOKEN:-}" ]; then
  ok "TURSO_API_TOKEN — present"
else
  warn "TURSO_API_TOKEN — missing (not loaded from OpenBao, see openbao-env status)"
fi

# Optional keys, each with what needs it. Never an unprefixed TURSO_DB_URL:
# app's `pnpm dev` would then query a hosted database instead of the local one.
optional_key() {
  if [ -n "${!1:-}" ]; then
    ok "$1 — present"
  else
    warn "$1 — missing (not loaded from OpenBao, see openbao-env status; only needed for $2)"
  fi
}
optional_key PREVIEW_TURSO_DB_URL "catalog's pnpm seed --preview and turso-stats"
optional_key PREVIEW_TURSO_DB_AUTH_TOKEN "catalog's pnpm seed --preview"
optional_key PROD_TURSO_DB_URL "catalog's pnpm seed --prod and turso-stats"
optional_key PROD_TURSO_DB_AUTH_TOKEN "catalog's pnpm seed --prod"
optional_key CLOUDFLARE_API_TOKEN "app's wrangler and push-cloudflare-secrets.sh"
optional_key CLOUDFLARE_ACCOUNT_ID "app's wrangler and push-cloudflare-secrets.sh"

if [ -n "${TURSO_DB_URL:-}" ]; then
  warn "TURSO_DB_URL — set: app's pnpm dev would query that database instead of catalog's local one (use the PREVIEW_/PROD_ prefixed names)"
fi

if [ -n "${FEEDBACK_GITHUB_TOKEN_EXPIRES:-}" ]; then
  days_left=$(( ($(date -d "$FEEDBACK_GITHUB_TOKEN_EXPIRES" +%s) - $(date +%s)) / 86400 ))
  if [ "$days_left" -lt 0 ]; then
    fail "FEEDBACK_GITHUB_TOKEN — expired on $FEEDBACK_GITHUB_TOKEN_EXPIRES (tuxery.store/feedback can't file issues)"
  elif [ "$days_left" -lt 21 ]; then
    warn "FEEDBACK_GITHUB_TOKEN — expires in $days_left days ($FEEDBACK_GITHUB_TOKEN_EXPIRES): renew it, then update OpenBao and the tuxery-web Worker secret"
  else
    ok "FEEDBACK_GITHUB_TOKEN — valid until $FEEDBACK_GITHUB_TOKEN_EXPIRES"
  fi
fi

# ── Workspace repos ───────────────────────────────────────────────────────────
echo ""
echo "── Workspace repos ──"

if [ -w /workspaces ]; then
  ok "/workspaces — writable by $(whoami) (sibling repos can be cloned)"
else
  fail "/workspaces — not writable by $(whoami) (sibling clones will fail with 'Permission denied'; re-run setup-container.sh)"
fi

for repo in .dev .github app catalog; do
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
