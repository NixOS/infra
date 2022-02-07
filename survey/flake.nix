# To bootstrap:
#   $ nix-shell -p nixUnstable git --run "nix build --experimental-features 'nix-command flakes' ~/nixos-org-configurations/survey#nixosConfigurations.survey.config.system.build.toplevel"
#   $ ./result/bin/switch-to-configuration test
#
# To update:
#   $ nixos-rebuild switch --flake ~/nixos-org-configurations/survey

{
  # TODO: temporary bump until the following PR is merged
  #       https://github.com/NixOS/nixpkgs/pull/157832
  inputs.nixpkgs.url = "github:garbas/nixpkgs/update-limesurvey";

  outputs = flakes @ { self, nixpkgs }: {
    nixosConfigurations.survey = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules =
        [
          "${nixpkgs}/nixos/modules/virtualisation/amazon-image.nix"
          ../modules/common.nix
          ({ config, pkgs, lib, ... }:
          {
            ec2.hvm = true;

            networking.hostName = "survey";
            networking.firewall.allowedTCPPorts = [ 80 443 ];

            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

            nix.package = pkgs.nixUnstable;
            nix.registry.nixpkgs.flake = nixpkgs;

            # needed since we use latest nixpkgs and we should probably
            # backport the limesurvey update to 21.11 channel
            nix.extraOptions = lib.mkForce
              ''
                experimental-features = nix-command flakes
              '';

            users.users.root.openssh.authorizedKeys.keys = with import ../ssh-keys.nix; [ eelco garbas ];

            services.limesurvey.enable = true;
            services.limesurvey.virtualHost.hostName = "survey.nixos.org";
            services.limesurvey.virtualHost.adminAddr = "webmaster@nixos.org";
            services.limesurvey.virtualHost.enableACME = true;
            services.limesurvey.virtualHost.forceSSL = true;

            security.acme.defaults.email = "webmaster@nixos.org";
            security.acme.acceptTerms = true;

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
