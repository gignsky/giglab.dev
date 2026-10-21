# AGENTS.md

This file guides coding agents (Claude Code and others) working in this
repository. `CLAUDE.md` is a symlink to it.

## What this is

**giglab.dev** is an auto-updating board of Lord Gig's current and upcoming
projects and their statuses, with a `/status` subpage tracking live fleet
service health (Gatus, monitors as code). It is also the **testbed for containers in
gigpkgs' inputMan**: this flake defines its own container, gigpkgs discovers
it, and spacedock runs it.

**Read [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) before any change.** It
holds the rulings, the open items and the phase plan. The repo is in
**Phase 1**: `flake.nix`, `site/` (Astro, the Annunciator landing page) and a
provisional `projects/` registry have landed; the Typst route (§3.2) and the
rest of Phase 1's deliverables are still open. The **visual direction is
chosen**: build from [`docs/design/`](docs/design/). It holds the landing-page handoff spec
(`landing-annunciator.md`), the design-system tokens (`tokens.json`, both
themes) and the canvas artboard's source (`reference/`, structure only, never
shipped). Gentium is the site's typeface and IBM Plex Mono is for machine
readouts only. Use only tokens; invent no new colours, faces or radii.

## Layout (keep this table true as phases land)

| Path | What |
|---|---|
| `site/` | Astro, **static output** (no SSR adapter). The Annunciator landing page lives here. |
| `projects/` | Project registry (**provisional** JSON-per-project shape; see `projects/README.md` and ARCHITECTURE.md §7 item 5), the source of truth for what is shown. No Typst write-ups yet. |
| `server/` | *(Phase 2, not yet created)* Rust binary: serves `dist/`, `/api/*`, polls GitHub / gigpkgs news / Gatus into SQLite |
| `nix/container-config.nix` | *(Phase 2, not yet created)* The container's fill-in items (dot-spacedock `lib/container-config` pattern); `containers.<sys>.giglab` (for inputMan discovery) lands with it |
| `flake.nix` | `devShells.default` (Node, typst, just, roll-flow); `packages.site` (Nix-built Astro output) and `packages.image` (OCI image, static-web-server over `packages.site` -- an interim stand-in for the Rust server) |
| `justfile` | Recipes for running the site locally (`dev`, `build`, `preview`, `check`, `clean`); run `just` inside `nix develop` to list them |
| `docs/` | Architecture, design handoff and runbooks |

## Commands (keep this table true as they come to exist)

```sh
nix develop                         # Node, typst, just, roll-flow (cargo lands with server/, Phase 2)
npm --prefix site install           # install dependencies
npm --prefix site run dev           # Astro dev server
npm --prefix site run build         # static build into site/dist/
npm --prefix site run check         # astro check (type-checks .astro files)

just                                 # list recipes (justfile)
just dev                             # dev server, reachable on the LAN by default
just dev 127.0.0.1                   # dev server, restricted to localhost (recipe args are positional)
just build                           # static build into site/dist/
just preview [host] [port]           # serve the production build (same host/port args as dev)
just check                           # astro check
just clean                           # remove gitignored build output + the content-layer cache

nix build .#site                    # Nix-built static site (dist/ as a store path)
nix build .#image                   # OCI image (static-web-server over .#site, :8800)
podman load -i result && podman run --rm -p 8800:8800 giglab-dev:latest   # smoke-test it

# Not yet real -- land with their phase:
cargo run --manifest-path server/Cargo.toml   # Phase 2
nix eval .#containers.x86_64-linux.giglab   # inspect the container spec -- Phase 2 (inputMan discovery)
```

For the Astro dev server, use background mode:
`astro dev --background`, then `astro dev stop | status | logs`.

`just dev`/`just preview` default to `host=0.0.0.0` (LAN-reachable) and open the
port in the host firewall for just that run, reverting it on exit -- mirrors
kottonmouth's `roll/3-1015-open-port-for-local-testing`. This is a per-invocation
dev convenience, not a host fact: it never touches persistent firewall config,
which still belongs in `.dotfiles` per the ground rule below.

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
