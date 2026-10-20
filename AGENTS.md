# AGENTS.md

This file guides coding agents (Claude Code and others) working in this
repository. `CLAUDE.md` is a symlink to it.

## What this is

**giglab.dev** is an auto-updating board of Lord Gig's current and upcoming
projects and their statuses. It is also the **testbed for containers in
gigpkgs' inputMan**: this flake defines its own container, gigpkgs discovers
it, and spacedock runs it.

**Read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) before any change.** It
holds the rulings, the open items and the phase plan. The repo is at
**Phase 0 (plan only, no code yet)**. Code design and styling are undecided,
so do not invent a visual direction unasked.

## Layout (planned — create as phases land)

| Path | What |
|---|---|
| `site/` | Astro, **static output** (no SSR adapter) |
| `projects/` | Project registry, the source of truth for what is shown; Typst write-ups |
| `server/` | Rust binary: serves `dist/`, `/api/*`, polls GitHub / gigpkgs news / Gatus into SQLite |
| `nix/container-config.nix` | The container's fill-in items (dot-spacedock `lib/container-config` pattern) |
| `flake.nix` | `packages.{site,server,image}`, `containers.<sys>.giglab`, `devShells.default` |
| `docs/` | Architecture and runbooks |

## Commands (planned — keep this table true as they come to exist)

```sh
nix develop                         # Node, cargo, typst, roll-flow
npm --prefix site run dev           # Astro dev server
cargo run --manifest-path server/Cargo.toml
nix build .#image                   # OCI image tarball
nix eval .#containers.x86_64-linux.giglab   # inspect the container spec
```

For the Astro dev server, use background mode:
`astro dev --background`, then `astro dev stop | status | logs`.

## Ground rules

- **nixpkgs follows `github:gignsky/gigpkgs/gigpkgs-unstable`.**
- **The container spec holds no host facts.** Secret *paths*, firewall,
  TLS and the front door belong in `gignsky/.dotfiles` (spacedock). The spec
  may only *name* env files it needs.
- **Private repos are never queried for detail or shown beyond curated
  text.** Respect `visibility` in the registry.
- **The project `status` is curated.** Live signals (pushes, rolls, releases,
  uptime) enrich an entry and never overwrite it.
- **Static first.** Every page must render meaningfully from the build-time
  snapshot with JavaScript off and the server's poller cold.
- **Do not add a Cloudflare tunnel.** The way in is DDNS → spacedock host
  nginx, which also serves ad-hoc `*.giglab.dev` demo sites.
- **TLS always.** `.dev` is HSTS-preloaded, so nothing works over plain HTTP.

## Workflow

- Branches flow `roll/N-MMDD-slug` → `rolling` → `master` via
  [roll-flow](https://github.com/gignsky/roll-flow) (`rf create | verify |
  graduate | promote`). Run `rf` inside the dev shell.
- Never commit secrets. Inspect `git status`, `git diff` and `git log` before
  staging.
- Commit messages carry: a descriptive title; `[ ] Reviewed by Lord G.`; a
  file tree diff; host status; the agent's signature; `---`; additional
  context.
- `#FERREN`, `#CLAUDE` (any `#AGENT_NAME`) in a file are notes addressed to
  the agent. `#G` marks Lord Gig's own reply: answer it in place and never
  remove it.

## Sibling repos for patterns

- `gignsky/kottonmouth` — Astro + Rust keeper + OCI image; the closest sibling
- `gignsky/christina-website` — council-pattern flake and roll-flow gates
- `gignsky/gigpkgs` — inputMan (`pkgs/programs/inputMan/`), container engine
  (`modules/nixos/containers.nix`), channel derivation (`channels.yml`)
- `gignsky/.dotfiles` — `containers/services/*.nix`, `hosts/spacedock/`
