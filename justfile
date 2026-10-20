# Run inside `nix develop`. `just` lists recipes.

default:
    @just --list

# One-time local setup: install site/ dependencies if missing.
setup:
    #!/usr/bin/env bash
    set -euo pipefail
    [ -d site/node_modules ] || npm --prefix site install

# Astro dev server, reachable from another device on the LAN by default (open the
# page by its http://<network-ip>:<port>, printed below -- hostnames are blocked by
# Vite's own DNS-rebinding guard). Pass host=127.0.0.1 to restrict to localhost only
# (skips the firewall rule below). Mirrors kottonmouth's roll/3-1015-open-port-for-local-testing.
dev host="0.0.0.0" port="4321": setup
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{ host }}" != "127.0.0.1" ]; then
      # NixOS firewall drops unsolicited traffic by default; open it for this run only.
      sudo iptables -C INPUT -p tcp --dport {{ port }} -j ACCEPT 2>/dev/null \
        || sudo iptables -I INPUT -p tcp --dport {{ port }} -j ACCEPT
      trap 'while sudo iptables -D INPUT -p tcp --dport {{ port }} -j ACCEPT 2>/dev/null; do :; done' EXIT
    fi
    cd site
    npm run tokens
    npx astro dev --host {{ host }} --port {{ port }}

# Type-check the Astro project (astro check).
check: setup
    npm --prefix site run check

# Static build into site/dist/.
build: setup
    npm --prefix site run build

# Serve the production build, reachable from another device on the LAN by default.
# Pass host=127.0.0.1 to restrict to localhost only (skips the firewall rule below).
preview host="0.0.0.0" port="4321": build
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{ host }}" != "127.0.0.1" ]; then
      sudo iptables -C INPUT -p tcp --dport {{ port }} -j ACCEPT 2>/dev/null \
        || sudo iptables -I INPUT -p tcp --dport {{ port }} -j ACCEPT
      trap 'while sudo iptables -D INPUT -p tcp --dport {{ port }} -j ACCEPT 2>/dev/null; do :; done' EXIT
    fi
    cd site
    npx astro preview --host {{ host }} --port {{ port }}

# Remove gitignored build output and the content-layer cache. Keeps node_modules otherwise.
clean:
    rm -rf site/dist site/.astro site/node_modules/.astro result result-*
