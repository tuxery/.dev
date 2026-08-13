# AGENTS.md — Tuxery `.dev`

This repository is the **shared workspace** for the Tuxery organization.

## Language

**All content in all Tuxery repositories must be in English** — code, comments,
doc-comments, commit messages, issues, pull requests, specs, and configuration.
This rule applies to every sibling repository. No exceptions.

## Scope

- VS Code multi-root workspace (`tuxery.code-workspace`)
- devcontainer setup (`.devcontainer/`)
- shared AI / agent guidance

This repository contains **no product runtime code** — it is configuration
and documentation only.

## Workspace structure

All repositories are cloned as siblings under `/workspaces/` by
`.devcontainer/setup-container.sh`'s `postCreateCommand` step — nothing is
bind-mounted from the host. This is what makes the devcontainer work
identically on a local checkout (Docker Desktop/WSL2) and on GitHub
Codespaces, which only ever checks out the one repo you launch the
codespace from.

| Path | Repo | Purpose |
| --- | --- | --- |
| `/workspaces/.dev` | `tuxery/.dev` | This repo — orchestration |
| `/workspaces/.github` | `tuxery/.github` | Org-level GitHub config + reusable workflows |
| `/workspaces/app` | `tuxery/app` | The product: Qwik UI, matching engine (`packages/matcher`), source connectors (`packages/sources`) |

## Devcontainer — available tools

The container is self-contained; no host toolchain installation is needed.

- Node.js 24, `pnpm` (via `helpers4/devcontainer/pnpm-store` + `typescript-dev`)
- `nub` — an accelerator (`nub run`, `nubx`) that delegates to pnpm; it is
  **not** a package manager replacement, pnpm remains the source of truth
  for dependencies and workspaces (`pnpm-workspace.yaml` in `app`)
- `gh` CLI

Not included yet: Playwright (`playwright-dev` feature) — it downloads
~500MB of browser binaries on every first build; add it back once `app`
actually has e2e tests to run.

## Roadmap & planning

TODOs, backlog ideas, and feature tracking live in the org's GitHub Project,
not in local files: **[Tuxery Project 1](https://github.com/orgs/tuxery/projects/1)**
(cross-repo — items belong to whichever `tuxery/*` repo they concern). Check it
before starting product work. Open a card there for new work instead of adding a
local TODO/roadmap file.

## Rules

- Treat this repository as configuration/documentation only — no product
  runtime code here.
- Add future repositories as siblings of `.dev/`, not nested inside it.
- Update `tuxery.code-workspace` and `.devcontainer/devcontainer.json`
  (both `TUXERY_REPOS` and the workspace `folders` list) together when a
  new sibling repository is added.
- Do not implement the product plan here unless the task is explicitly about shared tooling.
- Track TODOs, backlog ideas, and feature status as cards in
  [Project 1](https://github.com/orgs/tuxery/projects/1), not as local
  Markdown files (`TODO.md`, `ROADMAP.md`, etc.).

## Commit conventions

Format: `type(scope): <emoji> description`

| Type | Emoji | When |
| --- | --- | --- |
| `feat` | ✨ | New feature or file |
| `fix` | 🐛 | Correction |
| `docs` | 📝 | Documentation only |
| `chore` | 🔧 | Maintenance, config |
| `ci` | 👷 | CI/CD |
| `revert` | ⏪ | Reverts a previous commit |

### Allowed scopes

Scopes live in `scopes.json` at this repo's root (machine-readable source of truth,
also read by the `/commit` slash command):

| Scope | Maps to |
| --- | --- |
| `workspace` | `tuxery.code-workspace`, root-level config |
| `devcontainer` | `.devcontainer/` |
| `ai` | Agent guidance, prompt files |
| `docs` | `README.md` and other documentation |
| `ci` | `.github/workflows/` (if any) |

**Do not use a scope outside this list.** If a new top-level concern is added,
update `scopes.json` (and this table) and `.vscode/settings.json` together.

```text
docs(docs): 📝 document the local devcontainer quick start
chore(devcontainer): 🔧 add playwright-dev to devcontainer features
```

## Git workflow

Tuxery is an early-stage, mostly-solo project. `.dev` and `.github` are
meta/orchestration repos with no shipped product code — push straight to
`main`, no PR needed. For `app`, use short-lived feature branches and PRs;
adopt a stricter branch-protection / release-train model later if the project
grows collaborators or ships to production users, rather than pre-building
that process now.

## Inheritance

This repo's *shape* (`CLAUDE.md`, `scopes.json`, `commit-convention.json`,
`.claude/commands/commit.md`) is ported from
[helpers4/.dev](https://github.com/helpers4/.dev)'s canonical setup, via
[brig-id/roots](https://github.com/brig-id/roots)'s Codespaces-compatible
clone-based sibling setup. Deltas from that shape:
- **License: AGPL-3.0-or-later**, not LGPL — Tuxery is a hosted network
  service, not a library.
- Kept the **`.dev` name**, not `roots` — that name only made sense as part
  of brig-id's tree/forest metaphor across its repo set, which doesn't apply
  here.
- **`nub`** added as a pnpm accelerator (not present in either template org yet).
- Sibling repos are cloned in `postCreateCommand`, never bind-mounted from
  the host — brig-id/roots's fix for GitHub Codespaces support, applied here
  from day one instead of retrofitted later.
- Roadmap/feature tracking uses a GitHub Project (org-level, cross-repo)
  instead of local Markdown files, per this org's own bootstrap instructions.
- No Rust/cargo toolchain, no release-train git workflow — Tuxery is a
  TypeScript/Qwik monorepo, not brig-id's multi-crate Rust workspace, and is
  too early-stage for that process.
