{
  # Follows the house pattern from github.com/gignsky/council (flake-utils +
  # a pinned nixpkgs, devShell with a shellHook cheat-sheet). Closest sibling
  # for this divergence: christina-website (Astro, static, roll-flow gates).
  #
  # `packages.site`/`packages.image` are an early, interim slice of Phase 2:
  # the image just wraps the static build in static-web-server. There is no
  # Rust keeper, no /api, no SQLite poller yet -- no server/ exists. When it
  # does, this image is expected to be replaced by one built around it, and
  # nix/container-config.nix + containers.<sys>.giglab (the dot-spacedock
  # lib/container-config pattern, for inputMan discovery) still don't exist;
  # dotfiles references this flake's packages.image directly for now, the
  # same way it references avec-moi/kottonmouth (docs/ARCHITECTURE.md §8).
  description = "giglab.dev -- Astro, fully static, Rust keeper to come";

  inputs = {
    nixpkgs.url = "github:gignsky/gigpkgs/gigpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;

        # The Astro static build. Also needs projects/ (the registry) and
        # docs/design/tokens.json (site/scripts/build-tokens.mjs reads it) --
        # both outside site/, so the source tree is the three of them together.
        site = pkgs.buildNpmPackage {
          pname = "giglab-dev-site";
          version = "0.1.0";
          src = lib.fileset.toSource {
            root = ./.;
            fileset = lib.fileset.unions [
              ./site
              ./projects
              ./docs/design/tokens.json
            ];
          };
          sourceRoot = "source/site";
          npmDepsHash = "sha256-UiAJUqrFgOmX2gjl0lctO2VwlvKnkyanMeus/kb+1Ik=";
          # @astrojs/check + typescript are devDependencies (needed for `just check`,
          # not the build); skip installing them.
          npmInstallFlags = [ "--omit=dev" ];
          npmBuildScript = "build";
          installPhase = ''
            mkdir -p $out
            cp -r dist/. $out/
          '';
        };

        # OCI image, podman/spacedock-ready. Serves `site` on :8800 via
        # static-web-server (Rust, matching the footer's own stack claim) --
        # a placeholder for the real Rust server (Phase 2).
        image = pkgs.dockerTools.buildLayeredImage {
          name = "giglab-dev";
          tag = "latest";
          contents = [ pkgs.cacert ];
          config = {
            Entrypoint = [
              (lib.getExe pkgs.static-web-server)
              "--root"
              site
              "--port"
              "8800"
              "--host"
              "0.0.0.0"
            ];
            ExposedPorts."8800/tcp" = { };
          };
        };
      in
      {
        packages.site = site;
        packages.image = image;
        packages.default = image;

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.nodejs_22
            pkgs.git
            pkgs.typst
            pkgs.just
            # Branch workflow (roll/* -> rolling -> master). Gates live in
            # .roll-flow.toml and expect node/npm from this shell.
            pkgs.roll-flow
          ];

          shellHook = ''
            echo "giglab.dev dev shell"
            echo
            echo "  npm --prefix site install   -- install dependencies"
            echo "  npm --prefix site run dev   -- dev server on http://localhost:4321"
            echo "  npm --prefix site run build -- static build into site/dist/"
            echo "  npm --prefix site run preview -- serve the production build"
            echo
            echo "  just                    -- list recipes (justfile)"
            echo "  just dev                -- dev server, reachable on the LAN by default (opens a firewall port for the run)"
            echo "  just dev 127.0.0.1      -- dev server, restricted to localhost"
            echo "  just build              -- static build into site/dist/"
            echo "  just preview            -- serve the production build, reachable on the LAN by default"
            echo "  just check              -- astro check"
            echo "  just clean              -- remove gitignored build output + content-layer cache"
            echo
            echo "  nix build .#site        -- Nix-built static site (dist/ as a store path)"
            echo "  nix build .#image       -- OCI image (static-web-server over .#site, :8800)"
            echo
            echo "  rf status        -- roll-flow: where this branch sits"
            echo "  rf verify        -- run the gates for the next step, no merge"
            echo "  rf graduate      -- roll/* -> rolling  (roll_to_rolling_gates)"
            echo "  rf promote       -- rolling -> master  (rolling_to_main_gates)"
          '';
        };
      }
    );
}
