{ config, lib, pkgs, ... }:

with lib;

let
  sshKeys = rec {
    hydra-queue-runner = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyM48VC5fpjJssLI8uolFscP4/iEoMHfkPoT9R3iE3OEjadmwa1XCAiXUoa7HSshw79SgPKF2KbGBPEVCascdAcErZKGHeHUzxj7v3IsNjObouUOBbJfpN4DR7RQT28PZRsh3TvTWjWnA9vIrSY/BvAK1uezFRuObvatqAPMrw4c0DK+JuGuCNkKDGHLXNSxYBc5Pmr1oSU7/BDiHVjjyLIsAMIc20+q8SjWswKqL1mY193mN7FpUMBtZrd0Za9fMFRII9AofEIDTOayvOZM6+/1dwRWZXM6jhE6kaPPF++yromHvDPBnd6FfwODKLvSF9BkA3pO5CqrD8zs7ETmrV hydra-queue-runner@chef";
    rob = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHp3/OZP2nRS5bM9E1xN8Q2L398kC+m4guORjKsmGjwnnHvYnTml5puE2ogl8Wdenbk7hf82+vKyB+Tktrhx+IBSym4lY+czR6W+39hlPYdLbi980yxYT9KEMSyMWJEgPVJ1BZvHqsHQiad/L3eoPmAIMDmcn4mLh9rya5/oMW/ZgsA6j28ClvWkDRyaTmTLOa0Im4nLoSbdo8kJqU+JX/YcXlMKUvFfdMcj4T9YYwV98LPWHnEHFmjtBBUXRUAIESMXS6pm3Pep3czkKUL4UF0u9f17b40OWlLOF4IQWE2jM9yK09DiIQUzeU2XKRNW116DnmDL5QIRNrYnhkYeeQI3U6WnVTPdTU9kBVTDjhM+6U6/LClGJaWiglwwrzHtVELHgMi280qRefQEftb4CI/IbcPNAxetJevV68I5NAjfdnmMx8YbhfIiEqAJtBi4TvoH7HjDH+72+ZFjQ10fpz/p+DgUtiNlRKz8tXSZ+mbLuhmOJOxtGQTH3viYbSpG/4F9uKW1ekX0RMyRxVvpjMxHtCL4daJI4RTHFXy4R16OKAlYe7gs9sqv7O0IujLJPex/rnN2U4syGaSH5q3UnGxci6qgn8yLEhSP+Gj0xdv5H3fVjr/kNNZGWDOz6nDUaJT+eWlmWU7hOvm0ricrz9GEPUTQ0Rh70sWTQFq3poWQ== cardno:000606167509";
    rob-build = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCoQ7lzDDNH+8VZsw2SQ58EWrfLdeJKQHTQAqOOgOkfXtCt5WeWsdEFovrX2Wt4di6lgX4EH9xRp+1Owv5+WCorgPIdqACqS8nfcFZdy5TgPDNnK0ZpHaud7do8zrHkOqUBQ4mvfcr3mZ+aYxA03jGOAKR7aifInjzHF3bgyG5S6W1o9YxJ8bG3RLpAn1BZOs9diMkyD3vyb3oPo5vhf3U09Af0H3dnZUaAuKUAxN9HKoRg/DpuixkfbwGDHUvwxpypbPTBGzUv/F8m4irjw4rZGopZJn8rGwf9vHhq6OjIAta+/oArqkRovXN/DVcTDWCYS+vMGesOjRpTXQyqCxdR1wxi79UQlSxvYBuk7mw5SqCRya/kIDNC9J8h/KA9MCUFbkHmVxqjq+KLWYTHntem6SqZHpt+8QkypGuzJ2EPvaPBk9JqYfNRIX2dFjLVth0idWp8JeaGyFBUWDY9d5B+/9+jWY+Ze/t9xP40W7ca73XZsJSoJuwyNOu6XgQf9O0=";
    grahamc = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2LEAcTqOhZ3+zv6/VO+4Tts5pkm/tnDt0TIaIAVr+O\nssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILBPW2syaEH82DrqIl8/7/ypTgyfK8CRRTBEA4AmMB1l";
  };
  environment = concatStringsSep " "
    [
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];

  authorizedNixStoreKey = key:
    "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --write\" ${key}";
in

{
  environment.systemPackages =
    [
      config.nix.package
    ];

  programs.bash.enable = true;
  programs.bash.enableCompletion = false;

  #services.activate-system.enable = true;

  services.nix-daemon.enable = true;
  nix.gc.user = "root";

  nix.maxJobs = 8;
  nix.buildCores = 1;
  nix.gc.automatic = true;
  nix.gc.interval = { Minute = 15; };
  nix.gc.options = let
      gbFree = 50;
  in "--max-freed $((${toString gbFree} * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))";

  # If we drop below 20GiB during builds, free 20GiB
  nix.extraOptions = ''
    min-free = ${toString (30*1024*1024*1024)}
    max-free = ${toString (50*1024*1024*1024)}
    extra-platforms = aarch64-darwin
  '';

  environment.etc."per-user/root/ssh/authorized_keys".text = concatStringsSep "\n"
    ([
      (authorizedNixStoreKey sshKeys.hydra-queue-runner)
      (authorizedNixStoreKey sshKeys.rob-build)
      (authorizedNixStoreKey sshKeys.grahamc)
    ]);

  environment.etc."per-user/nixos/ssh/authorized_keys".text = concatStringsSep "\n"
    ([
      sshKeys.rob
      sshKeys.grahamc
    ]);

  system.activationScripts.postActivation.text = ''
    printf "disabling spotlight indexing... "
    mdutil -i off -d / &> /dev/null
    mdutil -E / &> /dev/null
    echo "ok"

    printf "configuring ssh keys for hydra on the root account... "
    mkdir -p ~root/.ssh
    cp -f /etc/per-user/root/ssh/authorized_keys ~root/.ssh/authorized_keys
    chown root:wheel ~root ~root/.ssh ~root/.ssh/authorized_keys
    echo "ok"

    printf "configuring ssh keys for rob on the nixos account... "
    mkdir -p ~nixos/.ssh
    cp -f /etc/per-user/nixos/ssh/authorized_keys ~nixos/.ssh/authorized_keys
    chown nixos:staff ~nixos/.ssh ~nixos/.ssh/authorized_keys
    echo "ok"
  '';

  launchd.daemons.prometheus-node-exporter = {
    script = ''
      exec ${pkgs.prometheus-node-exporter}/bin/node_exporter
    '';

    serviceConfig.KeepAlive = true;
    serviceConfig.StandardErrorPath = "/var/log/prometheus-node-exporter.log";
    serviceConfig.StandardOutPath = "/var/log/prometheus-node-exporter.log";
  };
}

