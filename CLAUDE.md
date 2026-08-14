# Claude Code — Tuxery workspace

Full canonical rules (commit format, restrictions, language) live in
[AGENTS.md](AGENTS.md). This file adds Claude Code-specific context.

## Workspace layout

All repos are cloned as siblings at `/workspaces/<name>` by
`.devcontainer/setup-container.sh`'s `postCreateCommand` (not bind-mounted —
this is what makes the devcontainer work on GitHub Codespaces as well as
local Docker Desktop/WSL2), and open together in `tuxery.code-workspace`:

| Path | Repo | Role |
| ---- | ---- | ---- |
| `/workspaces/.dev` | `.dev` | Orchestration — canonical AGENTS.md, devcontainer |
| `/workspaces/.github` | `.github` | Org-level GitHub config + reusable workflows |
| `/workspaces/app` | `app` | The product: Qwik UI (`apps/web`) |
| `/workspaces/catalog` | `catalog` | The data pipeline: source connectors, matching engine, rebuild scripts, persisted store |

## Common commands (run from `app`)

```bash
pnpm install
pnpm -r typecheck
pnpm -r lint
pnpm -r test
pnpm -r build
pnpm --filter web dev   # Qwik dev server on :5173
```

## Common gotchas

**Commit scopes**: always read `scopes.json` at the active repo root before choosing a scope.
Never invent a scope that isn't listed. Full type→emoji mapping: `/workspaces/.dev/commit-convention.json`.
Use `/commit` (Claude Code slash command) to auto-generate a message from staged changes.

**`nub`**: it's an accelerator on top of pnpm (`nub run`, `nubx`), not a package manager
replacement. Workspaces are still declared in `app/pnpm-workspace.yaml`.

**Environment self-check**: run `.devcontainer/test-container.sh` after a container rebuild to
verify `gh` auth, the JS toolchain, and cloned sibling repos are all in the expected state.

**Roadmap tracking**: check [Project 1](https://github.com/orgs/tuxery/projects/1) before
starting product work — TODOs, backlog ideas, and feature status live there as cards, not in
local files, per AGENTS.md's Rules section.

**Git workflow**: all `tuxery/*` repos push straight to `main`, no branches/PRs — this is a
solo-dev PoC stage (see each repo's `AGENTS.md` Git workflow section). Adopt feature branches
once the project actually ships or gains collaborators, not preemptively. Claude may commit once
authorized for the session, but never pushes — the user reviews and pushes themselves (see
memory: commit authorization is per-turn, push is never Claude's to do).

## AI persistence

`~/.claude` is bind-mounted from the host and symlinked at every container start by
`claude-dev`. Memory, credentials, and settings survive all rebuilds.
