#!/usr/bin/env bash
set -euo pipefail

# /workspaces itself, and every named-volume mount point declared in
# devcontainer.json's "mounts" (the per-repo volumes, shell-history,
# .vscode-server), come out root:root — only `.dev` (the bind-mounted
# workspaceFolder) inherits node ownership from the mount. Without this,
# `node` gets "Permission denied" writing into any of them.
sudo chown node:node /workspaces /workspaces/app /workspaces/catalog \
  /workspaces/.github /workspaces/.shell-history /home/node/.vscode-server \
  2>/dev/null || true

# ── Git commit signing (SSH format) ─────────────────────────────────────────────
# dotfiles-sync no longer bind-mounts ~/.ssh from the host (see devcontainer.json),
# so the public-key file that user.signingkey points at never lands in the
# container — even though VS Code/Codespaces still forward the host's ssh-agent
# (SSH_AUTH_SOCK) for the actual signing operation. Recover just that one public
# key — it isn't sensitive — from whatever the forwarded agent already has
# loaded, matched to git's configured user.email. Generic across teammates:
# nothing here is hardcoded to a specific key filename.
if [ "$(git config --get gpg.format 2>/dev/null || true)" = "ssh" ]; then
  signingkey_path="$(git config --get user.signingkey 2>/dev/null || true)"
  signingkey_path="${signingkey_path/#\~/$HOME}"
  user_email="$(git config --get user.email 2>/dev/null || true)"
  if [ -n "$signingkey_path" ] && [ ! -f "$signingkey_path" ] && [ -n "$user_email" ] \
    && command -v ssh-add >/dev/null 2>&1; then
    if pubkey="$(ssh-add -L 2>/dev/null | grep " ${user_email}\$")" && [ -n "$pubkey" ]; then
      mkdir -p "$(dirname "$signingkey_path")"
      echo "$pubkey" > "$signingkey_path"
      chmod 644 "$signingkey_path"
      echo "✓ Recovered SSH signing public key for commit signing ($signingkey_path)."
    else
      echo "! Commit signing key missing ($signingkey_path) and no matching key in ssh-agent — commits will fail to sign."
    fi
  fi
fi

ORG="${TUXERY_ORG:-tuxery}"
REPOS="${TUXERY_REPOS:-.github}"

# ── Clone sibling repositories ──────────────────────────────────────────────────
# Each sibling repo lives on its own named Docker volume (see devcontainer.json's
# "mounts"), not a host bind mount. That's deliberate: bind-mounting `../<repo>`
# from the host only works for a local Docker Desktop/WSL2 checkout where all
# repos were pre-cloned side by side; it silently breaks GitHub Codespaces, which
# only ever checks out the one repo you launched the codespace from. The volume
# means a plain "Rebuild Container" keeps whatever was cloned/committed here —
# this loop only actually clones on a fresh volume (first-ever run, or after a
# full teardown: `docker volume rm`, deleted Codespace), via the
# already-available check below.
echo "Setting up ${ORG} workspace..."

for repo in $REPOS; do
  target="/workspaces/${repo}"

  if [ -d "${target}/.git" ] || [ -n "$(ls -A "${target}" 2>/dev/null || true)" ]; then
    echo "✓ ${repo}: already available"
    continue
  fi

  echo "→ ${repo}: cloning sibling repository"
  if command -v gh >/dev/null 2>&1; then
    gh repo clone "${ORG}/${repo}" "${target}" || echo "! ${repo}: clone failed"
  else
    git clone "https://github.com/${ORG}/${repo}.git" "${target}" || echo "! ${repo}: clone failed"
  fi
done

echo "✓ Workspace repos ready."
echo ""

# ── Turso CLI ────────────────────────────────────────────────────────────────────
# No official/reliable devcontainer Feature exists for this (checked containers.dev
# and the devcontainers/features registry — the one community "tursodb" Feature is
# for Turso's embedded SQLite-compatible engine, a different product from this CLI).
# Plain install for now; worth promoting to a ghcr.io/helpers4/devcontainer Feature
# later if another project needs it too.
if command -v turso >/dev/null 2>&1 || [ -x "$HOME/.turso/turso" ]; then
  echo "✓ Turso CLI: already available"
else
  echo "→ Installing Turso CLI (local libSQL dev server — see catalog/AGENTS.md)..."
  if curl -sSfL https://get.tur.so/install.sh | bash >/dev/null 2>&1; then
    echo "✓ Turso CLI installed."
  else
    echo "! Turso CLI install failed — app's \`pnpm dev\` needs it. Install manually:"
    echo "  curl -sSfL https://get.tur.so/install.sh | bash"
  fi
fi

echo ""
echo "✓ Tuxery workspace ready."
