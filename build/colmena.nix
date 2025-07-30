# heavily adapted from https://github.com/juspay/colmena-flake
# Original license: GNU Affero General Public License v3.0
{
  config,
  lib,
  self,
  inputs,
  ...
}:
{
  options.colmena = {
    hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              targetHost = lib.mkOption {
                type = lib.types.str;
                default = "${name}.nixos.org";
                description = ''
                  The target host for colmena nodes
                '';
              };

              targetUser = lib.mkOption {
                type = lib.types.str;
                default = "root";
                description = ''
                  The target user for colmena nodes
                '';
              };
            };
          }
        )
      );
      description = ''
        Deployment configuration for colmena nodes
      '';
      example = {
        node1 = {
          targetHost = "node1.nixos.org";
          targetUser = "foo";
        };
      };
    };

    system = lib.mkOption {
      type = lib.types.str;
      description = ''
        The system for colmena nodes
      '';
      default = "x86_64-linux";
    };
  };
  config.flake.colmenaHive = inputs.colmena.lib.makeHive self.outputs.colmena;
  config.flake.colmena = {
    meta = {
      nixpkgs = inputs.nixpkgs.legacyPackages.${config.colmena.system};
      # https://github.com/zhaofengli/colmena/issues/60#issuecomment-1510496861
      nodeSpecialArgs = builtins.mapAttrs (_: value: value._module.specialArgs) self.nixosConfigurations;
    };
  }
  // builtins.mapAttrs (name: _: {
    imports = (self.nixosConfigurations.${name})._module.args.modules ++ [
      {
        deployment = config.colmena.hosts.${name};
      }
    ];
  }) config.colmena.hosts;
}
