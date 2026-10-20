# giglab.dev — Architecture

> Status: **plan, pre-code.** Ruled 2026-10-20. Code design and visual styling
> are deliberately left open; this document fixes *how the site functions* and
> *how it reaches spacedock*.

## 1. Purpose

giglab.dev is the living ledger of the Realm: **every current and upcoming
project, with its status, kept up to date automatically.** It should be
intuitive to browse and pleasant to read, with
[Typst](https://typst.app/) used for the typographically rich parts (project
write-ups, status sheets, anything mathematical or tabular that deserves
better than Markdown).

It doubles as the **testbed for containers in gigpkgs' inputMan**: the site is
shipped as a container *defined by this flake*, discovered by inputMan, and
run on spacedock straight from gigpkgs.

## 2. Shape

```
                       ┌───────────────── gignsky/giglab.dev (this repo) ─────────────────┐
                       │ site/      Astro, static output (+ Typst via astro-typst or CLI)  │
                       │ server/    Rust: serves site, /api/*, polls project sources       │
                       │ projects/  the registry — one entry per project (Typst + metadata)│
                       │ nix/container-config.nix   the container's fill-in items          │
                       └──────────────────────────────┬───────────────────────────────────┘
                                                      │ inputman install/update giglab-dev
                                                      ▼
   gignsky/gigpkgs ── roll → rolling → master ── channels.yml derives ──► gigpkgs-unstable
                                                      │
                                                      ▼ dotfiles input (gigpkgs-unstable), auto-upgrade
   spacedock ── gigpkgs.containers.fromInputs.giglab ──► podman: giglab  127.0.0.1:8800
                                                      ▲
   host nginx (TLS, front door) ──── giglab.dev ──────┘
             └── <name>.giglab.dev ──► ad-hoc demo sites on the host
                       ▲
   visitor ──► DNS (DDNS updater on memory-alpha) ──► home IP ──► router forward ──► spacedock
```

## 3. Components

### 3.1 Site — `site/` (Astro, static)

- Astro with **static output**, the same as kottonmouth and christina-website.
  There is no SSR adapter: the Rust server owns everything dynamic.
- Pages (high level): **index** (the board of all projects by status),
  **project page** per registry entry, **upcoming**, **about/now**. The
  layout is to be decided.
- Live parts (statuses, last activity, release versions) are islands that
  read `/api/*`. The build also embeds a snapshot so that a page with
  JavaScript off, or with the server's poller cold, still shows the last-known
  state.

### 3.2 Typst

There are two candidate routes. Prove one in Phase 1 before committing to it:

| Route | How | For | Against |
|---|---|---|---|
| **astro-typst** | `.typ` files act as pages and components (`<Typst>`), rendered to HTML or SVG at build time | Native to Astro; Typst lives in content collections | Depends on typst.ts node-compiler prebuilt binaries, which need care under Nix (`buildNpmPackage` + autoPatchelf) |
| **typst CLI in the Nix build** | `typst compile --format svg` (or HTML export) as a build step before `astro build`; Astro includes the output | Pure Nix and reproducible; nixpkgs carries `typst` | Less integrated; no frontmatter/collections from `.typ` |

The Rust server may also render Typst at runtime through the `typst` crate,
for live status sheets. That is optional and comes later.

### 3.3 Projects registry — `projects/`

This is the source of truth for **what exists and what it is called**. Each
project has one entry with curated metadata and an optional Typst write-up:

| Field | Meaning |
|---|---|
| `slug`, `title`, `summary` | Identity |
| `status` | `idea · planned · active · paused · shipped · archived` (curated) |
| `repo` | e.g. `gignsky/gigpkgs`; optional, since upcoming projects have none |
| `visibility` | `public` or `private`. **Private repos are never queried for details or shown beyond the curated text** |
| `links`, `tags`, `started`, `target` | Optional |

The status stays curated because a repo's activity cannot tell *paused* from
*finished*. Live signals enrich the entry but never overrule it.

### 3.4 Server — `server/` (Rust)

The pattern follows the kottonmouth keeper:

- Serves the built `dist/` and `/api/*` from one binary. axum is the
  suggested framework.
- **Poller:** on an interval, gathers live signals for each public registry
  entry and caches them in SQLite under `/data`:
  - GitHub REST: last push, open issues and PRs, latest tag or release, and
    in-flight `roll/N-MMDD-slug` branches (roll-flow) as an "in progress"
    signal.
  - gigpkgs `news/entries`: what shipped and at which version (the gignews
    feed).
  - status.gignsky.com (Gatus): live up/down for projects that are services.
- Uses a fine-grained, read-only GitHub token from an env file (sops on
  spacedock). It has no write access to anything.
- Config comes from the environment, following the keeper's table style. It
  binds `127.0.0.1:8800` by default, and the host front door is the only way
  in.

### 3.5 Container spec — `nix/container-config.nix`

This follows the **dot-spacedock `lib/container-config` pattern**: one `.nix`
file holds *every* fill-in item for the container, and everything else is
derived from it.

```nix
# shape only — exact fields settle in Phase 2
{
  hostname    = "giglab";
  image       = "giglab";               # tagged with `version`
  version     = "<from Cargo.toml / package.json>";
  imageFile   = <packages.${system}.image>;
  autoStart   = true;
  ports       = [ "127.0.0.1:8800:8800/tcp" ];
  volumes     = [ "/var/lib/giglab:/data" ];
  environment = { TZ = "America/New_York"; GITHUB_OWNER = "gignsky"; };
  environmentFiles = [ "giglab-env" ];  # NAMES only; the host maps them to sops paths
  excludeFromAdHocEnvironment = [ ];
  extraOptions = [ ];
}
```

The flake exposes it as **`containers.<system>.giglab`**. The spec holds **no
host facts**: secret paths, firewall rules and the front door all live in
dotfiles. The `podman*` strings for ad-hoc runs are derived from the same
attrset, as `podman-functions.nix` did in dot-spacedock.

### 3.6 Flake outputs

| Output | What |
|---|---|
| `packages.<sys>.site` | Astro build (`dist/`), with Typst rendered in |
| `packages.<sys>.server` | The Rust binary |
| `packages.<sys>.image` | `dockerTools.buildLayeredImage` of server + site |
| `packages.<sys>.default` | `image` |
| `containers.<sys>.giglab` | The container spec (§3.5); **this is what inputMan discovers** |
| `nixosModules.giglab` | Optional bare-systemd alternative |
| `devShells.default` | Node, cargo, typst, roll-flow (council pattern) |

`nixpkgs` follows **`github:gignsky/gigpkgs/gigpkgs-unstable`**.

## 4. Delivery — push to live

| Step | Mechanism | Phase |
|---|---|---|
| 1. Push to `master` here | roll-flow: `roll/*` → `rolling` → `master` | 1 |
| 2. gigpkgs takes the new rev | `inputman update giglab-dev`, on a roll in gigpkgs | 2 (manual) → 4 (Action) |
| 3. gigpkgs trunk → `gigpkgs-unstable` | Existing `channels.yml` derive on every trunk push | exists |
| 4. spacedock picks it up | dotfiles input on `gigpkgs-unstable`, plus `system.autoUpgrade` (or a timer) that updates that input and switches | 3 |
| 5. podman restarts on the new image | `virtualisation.oci-containers` sees a new `imageFile` | exists |

**inputMan work (in gigpkgs, Phase 2):** discover `containers.<sys>.*` as a
third output kind beside packages and modules. Write
`containers/inputs/<name>.nix` aggregators, extend the news entry with the
image version diff, and let `pin` materialize `giglab-<ver>` containers so
rolling back is a one-line switch. `gigpkgs.nixosModules.containers` gains
`fromInputs.<name>.{enable, overrides, environmentFiles}`.

**Optional Action (Phase 4):** a push here sends `repository_dispatch` to
gigpkgs. A workflow there runs `inputman update giglab-dev -y` on a fresh
roll and opens a PR, or graduates it automatically. This needs a PAT secret in
this repo.

## 5. Front door — spacedock host

- The **DDNS updater on memory-alpha** keeps `giglab.dev` pointed at the home
  IP. The router forwards public **443** to spacedock **`:1776`**, the
  front-door port. There is **no Cloudflare tunnel**.
- A **host-level reverse proxy** owns `:1776` (TLS). nginx is already enabled on
  spacedock. It routes by `Host`:
  - `giglab.dev` (+ `www`) → the giglab container on `127.0.0.1:8800`
  - `<name>.giglab.dev` → **ad-hoc demo sites** on the host. This is how
    giglab.dev stays usable for showing temporary work without touching the
    main site.
- **TLS is mandatory.** `.dev` is on the HSTS preload list, so browsers refuse
  plain HTTP for every `*.dev` name. Certificates come from
  `security.acme`. Wildcard demo subdomains need a **DNS-01** challenge,
  which requires API access at whoever hosts giglab.dev's DNS.
- **Outage behaviour:** when spacedock is down, the site is down. Ruled
  acceptable for now. Later, Cloudflare caching can be layered on by
  orange-clouding the DDNS record, which does not need a tunnel. That only
  works if the public port is one Cloudflare proxies (443, 8443, 2053, 2083,
  2087, 2096). Cloudflare would therefore reach the origin on 443, which the
  router already forwards to `:1776`.

## 6. Rulings (2026-10-20)

| Question | Ruling |
|---|---|
| Purpose | Auto-updating board of all current and upcoming projects with statuses; Typst for rich formatting |
| Hosting | Container on spacedock |
| Way in | DDNS (memory-alpha) → spacedock, no tunnel; giglab.dev also used for ad-hoc demo sites on spacedock |
| Front-door port | **1776** on spacedock (host nginx, TLS); router forwards public 443 → 1776 |
| Downtime | Accept for now; Cloudflare caching is a future option |
| Update channel | Follow **gigpkgs-unstable**, like dotfiles follows gigpkgs |
| GitHub Action | Willing to attempt (Phase 4) |
| Container spec format | The dot-spacedock `lib/container-config` pattern: one `.nix` file of fill-in items |

## 7. Open items

1. **Router forward.** Point public **443 → spacedock:1776**, replacing the
   old 8082 forward, so URLs carry no `:port`. Open 1776 in spacedock's
   firewall. ACME HTTP-01 would also need public 80; DNS-01 (item 2) avoids
   that.
2. **DNS host for giglab.dev**, which decides the ACME DNS-01 provider for the
   wildcard demo cert. (giglab.dev resolved to the home IP on 2026-10-20.)
3. **Demo-site convention.** Pick a fixed `demo.giglab.dev` → one port, or
   `<name>.giglab.dev` from a small attrset in dotfiles.
4. **Typst route** (§3.2).
5. **Registry format.** Typst metadata in `.typ`, or TOML beside each `.typ`.
6. **Auto-upgrade cadence** on spacedock, and whether it applies only to the
   `gigpkgs-unstable` input or to the whole host.

## 8. Phases

| Phase | Deliverable |
|---|---|
| 0 | This plan · `CLAUDE.md` |
| 1 | Flake + devShell + roll-flow gates; Astro skeleton; Typst route proven; registry with a few real entries; static build |
| 2 | Rust server + poller + SQLite; OCI image; `nix/container-config.nix` + `containers.<sys>.giglab`; **inputMan container discovery in gigpkgs** |
| 3 | spacedock: `gigpkgs-unstable` input, `fromInputs.giglab`, sops env, nginx front door + ACME, auto-upgrade |
| 4 | Optional `repository_dispatch` Action; demo-site convention; Cloudflare caching if wanted |

## References

- `gignsky/kottonmouth` — Astro + Rust keeper + OCI image + `containers/services` wiring (the closest sibling)
- `gignsky/christina-website` — Astro + council-pattern flake and roll-flow
- `gignsky/gigpkgs` — `pkgs/programs/inputMan/`, `modules/nixos/containers.nix`, `.github/workflows/channels.yml`
- `GeeM-Enterprises/dot-spacedock` — `lib/container-config/`, `lib/podman-functions.nix` (branch `container/pihole/updates`)
- `gignsky/.dotfiles` — `containers/services/`, `hosts/spacedock/`
- [astro-typst](https://github.com/OverflowCat/astro-typst)
