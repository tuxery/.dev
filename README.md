# Tuxery — `.dev`

Central orchestration workspace for the **Tuxery** organization.

This repository is the bootstrap entry point for development across the organization. It hosts:

- the shared [VS Code multi-root workspace](./tuxery.code-workspace)
- the shared [devcontainer](./.devcontainer/devcontainer.json)
- the workspace-level AI guidance shared across the org

It does **not** contain product runtime code — it is configuration and documentation only.

## Current layout

```text
tuxery/
├── .dev/        # this repo — workspace, devcontainer, AI guidance
├── .github/     # org-wide GitHub defaults and reusable workflows
├── app/         # the product: Qwik UI (queries catalog's dataset via Turso)
└── catalog/     # the data pipeline: source connectors, matching engine, persisted store
```

## Quick start — GitHub Codespaces (recommended)

Open a Codespace on `tuxery/.dev` directly from GitHub. `postCreateCommand`
clones every sibling repo listed in `.devcontainer/devcontainer.json`'s
`TUXERY_REPOS` into `/workspaces/<repo>` automatically — there's nothing to
pre-clone. This is the only devcontainer path this repo supports without any
manual setup.

If you want `gh` to stay authenticated inside the container (needed to clone
private/rate-limited resources and for `test-container.sh`'s checks), set a
Codespaces secret or export a token on the host **named `GH_TOKEN_FOR_TUXERY`**
before creating/reopening the codespace — not `GH_TOKEN` (that name is
deliberately different so it doesn't collide with a token you may already have
exported globally for other, unrelated projects):

```bash
export GH_TOKEN_FOR_TUXERY="$(gh auth token)"
```

## Quick start — local (Docker Desktop / WSL2)

### 1. Clone this repo

```bash
gh repo clone tuxery/.dev
```

### 2. Open the shared workspace

```bash
code .dev/tuxery.code-workspace
```

### 3. Reopen in the devcontainer

Same as Codespaces: sibling repos are cloned automatically by
`postCreateCommand`, nothing needs to be pre-cloned side by side on the host.
Export `GH_TOKEN_FOR_TUXERY` first (see above) so `gh`/`git` can clone them.

## Verifying the environment

After the container starts, run:

```bash
bash .devcontainer/test-container.sh
```

It checks `gh` auth, the JavaScript toolchain (node/pnpm/nub), and that every
sibling repo in `TUXERY_REPOS` was cloned successfully.

When a new repository is added to the organization, update
`.devcontainer/devcontainer.json` (`TUXERY_REPOS`) and `tuxery.code-workspace`
together.
