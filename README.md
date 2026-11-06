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

Open a Codespace on `tuxery/.dev` directly from GitHub. the `org-workspace`
feature clones the org's repos (see `.devcontainer/devcontainer.json`)
into `/workspaces/<repo>` automatically — there's nothing to
pre-clone. This is the only devcontainer path this repo supports without any
manual setup.

Secrets (`GH_TOKEN`, …) come from OpenBao — `kv/orgs/tuxery`, plus `kv/shared/*` — through the
[`openbao-env`](https://github.com/helpers4/devcontainer/tree/main/src/openbao-env) feature, into
every process of the container (VS Code included). On fajro, `devc up tuxery` hands the
container its credentials. In GitHub Codespaces, set the Codespaces secrets `BAO_ROLE_ID` and
`BAO_SECRET_ID` (AppRole `tuxery`) and give the codespace Tailscale access: OpenBao is only
reachable on the tailnet.

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
The secrets come from OpenBao (see above).

## Verifying the environment

After the container starts, run:

```bash
bash .devcontainer/test-container.sh
```

It checks `gh` auth, the JavaScript toolchain (node/pnpm/nub), and that every
expected sibling repo was cloned successfully.

When a new repository is added to the organization, update
the `org-workspace` options in `.devcontainer/devcontainer.json` and
`tuxery.code-workspace` together.
