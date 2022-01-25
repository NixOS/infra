# To bootstrap:
#   $ nix-shell -p nixUnstable git --run "nix build --experimental-features 'nix-command flakes' ~/nixos-org-configurations/survey#nixosConfigurations.survey.config.system.build.toplevel"
#   $ ./result/bin/switch-to-configuration test
#
# To update:
#   $ nixos-rebuild switch --flake ~/nixos-org-configurations/survey

{
  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  outputs = flakes @ { self, nixpkgs }: {
    nixosConfigurations.survey = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules =
        [
          "${nixpkgs}/nixos/modules/virtualisation/amazon-image.nix"
          ../modules/common.nix
          ({ config, pkgs, ... }:
          {
            ec2.hvm = true;
            networking.hostName = "survey";
            networking.firewall.allowedTCPPorts = [ 80 443 ];
            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
            nix.package = pkgs.nixUnstable;
            nix.registry.nixpkgs.flake = nixpkgs;
            users.users.root.openssh.authorizedKeys.keys = with import ../ssh-keys.nix; [ eelco garbas ];
          })
        ];
    };

    devShell.x86_64-linux =
      with nixpkgs.legacyPackages.x86_64-linux;
      mkShell {
        nativeBuildInputs = [
          awscli
          (terraform_0_15.withPlugins (p: with p; [ aws p.null external tls local ]))
        ];

        shellHook = ''
          alias tf=terraform
        '';
      };
  };
}
