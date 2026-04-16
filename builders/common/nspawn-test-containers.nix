{
  # From <https://github.com/NixOS/nixpkgs/blob/master/nixos/doc/manual/development/running-nixos-tests.section.md#system-requirements-sec-running-nixos-tests-requirements>:
  # > NixOS tests using systemd-nspawn containers require the Nix daemon to be
  # > configured with the following settings:
  nix.settings = {
    auto-allocate-uids = true;
    extra-system-features = [ "uid-range" ];
    experimental-features = [
      "auto-allocate-uids"
      "cgroups"
    ];
  };

  # Required for communication between nspawn containers and qemu vms.
  # Disabled for now, see <https://github.com/NixOS/infra/issues/987>.
  # nix.settings.sandbox-paths = [ "/dev/net" ];
}
