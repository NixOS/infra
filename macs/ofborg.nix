{
  imports = [
    ./common/nix.nix
    ./common/node-exporter.nix
    ./common/ofborg.nix
    ./common/ofborg-queue-builder.nix
    ./common/shells.nix
    ./common/spotlight.nix
    ./common/ssh.nix
    ./common/tools.nix
    ./common/workarounds.nix
  ];

  ids.gids.nixbld = 30000;
}
