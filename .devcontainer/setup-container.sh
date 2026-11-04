#!/usr/bin/env bash
set -euo pipefail

# Named-volume mount points come out root:root; hand VS Code Server's to node
# so extensions can install. (/workspaces and the shell history volume are
# handled by the org-workspace and shell-history features.)
sudo chown node:node /home/node/.vscode-server 2>/dev/null || true

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
