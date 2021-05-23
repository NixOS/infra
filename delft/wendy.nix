{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ./build-machines-dell-r815.nix ./sysstat.nix ./datadog.nix ];

  nix = {
    maxJobs = mkForce 24;
    buildCores = mkForce 12;
  };

  users.extraUsers.eelco =
    { description = "Eelco Dolstra";
      home = "/home/eelco";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [ (import ../ssh-keys.nix).eelco ];
    };

  users.extraUsers.danny =
    { description = "Danny Groenewegen";
      home = "/home/danny";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [ (import ../ssh-keys.nix).danny ];
      extraGroups = [ "wheel" ];
      createHome = true;
    };

  users.extraUsers.rbvermaa =
    { description = "Rob Vermaas";
      home = "/home/rbvermaa";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [ (import ../ssh-keys.nix).rob ];
    };

  security.pam.enableSSHAgentAuth = true;
}
