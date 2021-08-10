# To bootstrap:
#   $ nix-shell -p nixUnstable git --run "nix build --experimental-features 'nix-command flakes' ~/nixos-org-configurations/ngi0/silvan-demo#nixosConfigurations.modules.config.system.build.toplevel"
#   $ ./result/bin/switch-to-configuration test
#
# To update:
#   $ nixos-rebuild test --flake ~/nixos-org-configurations/ngi0/silvan-demo

{
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";

  outputs = { self, nixpkgs }: rec {

    nixosConfigurations.modules = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules =
        [
          "${nixpkgs}/nixos/modules/virtualisation/amazon-image.nix"
          ../../modules/common.nix
          ({ config, pkgs, ... }:
          {
            ec2.hvm = true;
            networking.hostName = "modules";
            networking.firewall.allowedTCPPorts = [ 222 ];
            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
            nix.package = pkgs.nixUnstable;
            nix.registry.nixpkgs.flake = nixpkgs;
            users.users.root.openssh.authorizedKeys.keys = with import ../../ssh-keys.nix; [ silvan ];
          })
        ];
    };

  };

}
