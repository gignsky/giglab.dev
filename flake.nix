{
  # Follows the house pattern from github.com/gignsky/council (flake-utils +
  # a pinned nixpkgs, devShell with a shellHook cheat-sheet). Closest sibling
  # for this divergence: christina-website (Astro, static, roll-flow gates).
  #
  # No Nix-built site/server/image package yet -- those land in Phase 2
  # alongside server/ and nix/container-config.nix (docs/ARCHITECTURE.md §8).
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
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.nodejs_22
            pkgs.git
            pkgs.typst
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
            echo "  rf status        -- roll-flow: where this branch sits"
            echo "  rf verify        -- run the gates for the next step, no merge"
            echo "  rf graduate      -- roll/* -> rolling  (roll_to_rolling_gates)"
            echo "  rf promote       -- rolling -> master  (rolling_to_main_gates)"
          '';
        };
      }
    );
}
