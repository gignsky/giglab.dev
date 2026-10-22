# Every fill-in item for the giglab container, in one place (the dot-spacedock
# `lib/container-config` pattern). The flake derives the rest from this:
# `packages.<sys>.image` is built from `image` + `version`, and
# `containers.<sys>.giglab` (what inputMan discovers) is this attrset plus the
# built `imageFile` and a ready-to-use `service` attrset.
#
# No host facts here: secret paths, firewall, TLS and the front door belong in
# gignsky/.dotfiles. Only *name* env files the container needs.
#
# Interim image (static-web-server over the static site): it has no /data
# state and reads no env, so there are no volumes, secrets or
# environmentFiles yet. They arrive with the Rust server (Phase 2).
{ lib }:
let
  # One source of truth for the version.
  version = (builtins.fromJSON (builtins.readFile ../site/package.json)).version;

  coreConfig = {
    hostname = "giglab";
    # Name baked into the image tarball; `version` is its tag. Must match
    # what the flake's image build uses, so `image` resolves to the loaded
    # tarball rather than a registry pull.
    image = "giglab-dev";
    inherit version;
    autoStart = true;
    # Loopback only: host nginx owns the front door (ARCHITECTURE.md §5).
    ports = [ "127.0.0.1:8800:8800/tcp" ];
    environment = {
      TZ = "America/New_York";
    };
    excludeFromAdHocEnvironment = [ ];
    extraOptions = [ ];
  };

  # Same derived strings as dot-spacedock's podman-functions.nix, for ad-hoc
  # `podman run`.
  podmanOptions = {
    podmanName = "--name ${coreConfig.hostname}-adHoc";
    podmanImage = "${coreConfig.image}:${coreConfig.version}";
    podmanPorts = lib.concatStringsSep " " (map (p: "--publish ${p}") coreConfig.ports);
    podmanEnvironment = lib.concatStringsSep " " (
      lib.mapAttrsToList (n: v: "--env ${n}=${v}") coreConfig.environment
    );
    podmanAdHocEnvironment = lib.concatStringsSep " " (
      lib.mapAttrsToList (n: v: "--env ${n}=${v}") (
        lib.filterAttrs (
          n: _: !(builtins.elem n coreConfig.excludeFromAdHocEnvironment)
        ) coreConfig.environment
      )
    );
    podmanExtraOptions = lib.concatStringsSep " " coreConfig.extraOptions;
  };
in
coreConfig // podmanOptions
