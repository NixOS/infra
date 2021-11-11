{ config, lib, pkgs, ... }:

with lib;

let
  narCache = "/var/cache/hydra/nar-cache";
in

{
  users.extraUsers.hydra.openssh.authorizedKeys.keys =
    with import ../ssh-keys.nix; [ eelco rob ];
  users.extraUsers.hydra-www.openssh.authorizedKeys.keys =
    with import ../ssh-keys.nix; [ eelco rob ];
  users.extraUsers.hydra-queue-runner.openssh.authorizedKeys.keys =
    with import ../ssh-keys.nix; [ eelco rob ];

  services.hydra-dev.enable = true;
  services.hydra-dev.logo = ./hydra-logo.png;
  services.hydra-dev.hydraURL = "https://hydra.nixos.org";
  services.hydra-dev.notificationSender = "edolstra@gmail.com";
  services.hydra-dev.smtpHost = "localhost";
  services.hydra-dev.useSubstitutes = false;
  services.hydra-dev.extraConfig =
    ''
      max_servers 30

      enable_google_login = 1
      google_client_id = 816926039128-ia4s4rsqrq998rsevce7i09mo6a4nffg.apps.googleusercontent.com

      github_client_id = b022c64ce4531ffc1031
      github_client_secret_file = /var/lib/hydra/www/keys/hydra-github-client-secret

      store_uri = s3://nix-cache?secret-key=/var/lib/hydra/queue-runner/keys/cache.nixos.org-1/secret&write-nar-listing=1&ls-compression=br&log-compression=br
      server_store_uri = https://cache.nixos.org?local-nar-cache=${narCache}
      binary_cache_public_uri = https://cache.nixos.org

      <Plugin::Session>
        cache_size = 32m
      </Plugin::Session>

      # patchelf:master:3
      xxx-jobset-repeats = nixos:reproducibility:1

      upload_logs_to_binary_cache = true

      # FIXME: Cloudfront messes up CORS
      #log_prefix = https://cache.nixos.org/

      log_prefix = https://nix-cache.s3.amazonaws.com/

      evaluator_workers = 8
      evaluator_max_memory_size = 4096

      max_concurrent_evals = 1

      max_unsupported_time = 86400

      allow_import_from_derivation = false

      <hydra_notify>
        <prometheus>
          listen_address = 0.0.0.0
          port = 9199
        </prometheus>
      </hydra_notify>
    '';

  systemd.tmpfiles.rules =
    [ "d /var/cache/hydra 0755 hydra hydra -  -"
      "d ${narCache}      0775 hydra hydra 1d -"
    ];

  users.extraUsers.hydra.home = mkForce "/home/hydra";

  systemd.services.hydra-queue-runner.restartIfChanged = false;
  systemd.services.hydra-queue-runner.wantedBy = mkForce [];
  systemd.services.hydra-queue-runner.requires = mkForce [];

  programs.ssh.hostKeyAlgorithms = [ "ssh-ed25519" "ssh-rsa" "ecdsa-sha2-nistp256" ];
  programs.ssh.extraConfig = mkAfter
    ''
      ServerAliveInterval 120
      TCPKeepAlive yes

      Host mac1-guest
      Hostname 10.254.2.1
      Port 2200
      Compression yes

      Host mac2-guest
      Hostname 10.254.2.2
      Port 2200
      Compression yes

      Host mac3-guest
      Hostname 10.254.2.3
      Port 2200
      Compression yes

      Host mac4-guest
      Hostname 10.254.2.4
      Port 2200
      Compression yes

      Host mac5-guest
      Hostname 10.254.2.5
      Port 2200
      Compression yes

      Host mac6-guest
      Hostname 10.254.2.6
      Port 2200
      Compression yes

      Host mac7-guest
      Hostname 10.254.2.7
      Port 2200
      Compression yes

      Host mac8-guest
      Hostname 10.254.2.8
      Port 2200
      Compression yes

      Host mac9-guest
      Hostname 10.254.2.9
      Port 2200
      Compression yes

      Host mac-m1-1
      Hostname 10.254.2.101
      Compression yes

      Host mac-m1-2
      Hostname 10.254.2.102
      Compression yes

      Host mac-m1-3
      Hostname 10.254.2.103
      Compression yes

      Host mac-m1-4
      Hostname 10.254.2.104
      Compression yes

      Host mac-m1-5
      Hostname 10.254.2.105
      Compression yes

      Host mac-m1-6
      Hostname 10.254.2.106
      Compression yes

      Host macstadium-x86-44911507
      Hostname 208.83.1.186
      Compression yes

      Host macstadium-x86-44911362
      Hostname 208.83.1.175
      Compression yes

      Host macstadium-x86-44911305
      Hostname 208.83.1.173
      Compression yes

      Host macstadium-m1-44911104
      Hostname 208.83.1.181
      Compression yes

      Host macstadium-m1-44911207
      Hostname 208.83.1.145
      Compression yes
  '';

  services.openssh.knownHosts = {

    # (for i in 10.254.2.{1,2,3,4,5,6,7,8,9}; do ssh-keyscan -t ssh-ed25519 -p 2200 $i 2> /dev/null; done) | sed -e 's/^/      { hostNames = [ "/' -e 's/ ssh/" ]; publicKey = "ssh/' -e 's/$/"; };/'; echo

    mac1-guest = { hostNames = [ "[10.254.2.1]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINkWZobdUDgoXyqzpcWUyBXz7pRCcqxRMS9z6Nyg8lJ/"; };
    mac2-guest = { hostNames = [ "[10.254.2.2]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICIzkQ2sjmphJL2oo1FSA/3F7/G+YTraWuPYUXBdZJ/t"; };
    mac3-guest = { hostNames = [ "[10.254.2.3]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDnJQyL2LlWjIE+4wGBZyTapXlCgwTZ+uBh7eoaGPfL"; };
    mac4-guest = { hostNames = [ "[10.254.2.4]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBq44jmyZD6fQY+WLPH3Dx9mQXzCK7ZBpfmYjATVvT7T"; };
    mac5-guest = { hostNames = [ "[10.254.2.5]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEKH3SXo9u27y105FLNz1PxrDMBZ0gAsBsC9t2ErHbx4"; };
    mac6-guest = { hostNames = [ "[10.254.2.6]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBNU5/bIy24ea7twM6j7QAKs1KWJADYNfov94N9YjlVz"; };
    mac7-guest = { hostNames = [ "[10.254.2.7]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8AwqnYcZhj1jINB5HMAT+VBl+rPH9TCeHPtZMwMIUJ"; };
    mac8-guest = { hostNames = [ "[10.254.2.8]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAYH18PbDKKNmRaRYdMbbSqJSC+g5yB83LLSNemxhoCE"; };
    mac9-guest = { hostNames = [ "[10.254.2.9]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4oOQBk3nRMKcPsDAL54jMAfSy9fwCyfH1qWwp1jwQt"; };

    mac-m1-1 = { hostNames = [ "10.254.2.101" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILIpNE/evvR5mVLslm4G5AV6pQ2wdpIl7FPGDh5wZPLF"; };
    mac-m1-2 = { hostNames = [ "10.254.2.102" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDyGCqoDh+BWnV1NIV2ucyb0WsXz5fH2hKDgC1dhN+Wq"; };
    mac-m1-3 = { hostNames = [ "10.254.2.103" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGtPVTcBWTENjQ3e9ry7pOTFHk316Ahm3VW1Ys0cMhVf"; };
    mac-m1-4 = { hostNames = [ "10.254.2.104" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk2OLBHfCV3yxXzAsgX0r9cQ3KvpESak6s+tYGJq6J4"; };
    mac-m1-5 = { hostNames = [ "10.254.2.105" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHbYjdeghSNg7bU/ER/pTSGwP7Fyd7+OteD06dP4gCfP"; };
    mac-m1-6 = { hostNames = [ "10.254.2.106" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8B5Ek8GhWCO5Qahl20CHn/txxvAweupuIbFmuLjciG"; };


    # Note that these IPS and SSH public keys are correct, but the machines are dedicated to ofborg for now,
    # and therefore should not and cannot be put in to rotation in hydra.
    macstadium-x86-44911305 = { hostNames = [ "208.83.1.173" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOtMZwCu5D/CRTTC8wvZWP+H7xkCCHjQZ//XVM4vmdZU"; };
    macstadium-x86-44911362 = { hostNames = [ "208.83.1.175" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHjQFkuDYP5qBgvFZvwbJb0g4CTV8/FcHPCOT7Wmlkmr"; };
    macstadium-x86-44911507 = { hostNames = [ "208.83.1.186" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMOMJFJhA4y5w72n3eRlb1RtcZc4gsc4UNHVQkBf6xZY"; };
    macstadium-m1-44911104 = { hostNames = [ "208.83.1.181" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOX5EjsuYGcHEoIIX9c3J12xkL+z3Dz/3xby9KnTGpVG"; };
    macstadium-m1-44911207 = { hostNames = [ "208.83.1.145" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICFDCv348yhWE2Tok+b2MALh8kNlgLGCCZqdaNLYN2U0"; };


    stan = { hostNames = [ "stan.ewi.tudelft.nl" "131.180.119.74" ]; publicKey = "ssh-dss AAAAB3NzaC1kc3MAAACBAL0SlYpGjDjPKrLIwoltYHHTYo/d6Ct2FQZKh4ltKOszWPYYAbs/YNSm2eFkvj0CGc3aastFuebz6+pRfvGMvqi4q6IoHwVvOkbWMadyuqrWIO+Z1YemZP/GAG69pLy+UyoydiSI83ycwPe4YARAU/cpBMNKJZbSxyrO80XatmtRAAAAFQC291WK+9M8+zI4KAtk6EqX0vqQ1QAAAIBd1YgRfdfRdu60BpR+3/YMbSYZMjRLFPyoSgmEQR2TtKfqsuKTsTREzB20iMgFlhEWb6C4r5y6jYDU85OOnvpf7zne22j6bKFDIiAbgsjUFHK1EB7+TBltf5yqq0FyNOy/PnLqVzOeGaUeCOc3Ris71Lxkm60oVF4mjut2d2UJ6AAAAIByuCH1bIIRb4za4yiiFQUz2CBX1XHhBn/h/LhNMLuyCTciG6tkppGBAgq5rWrNhjaEc7dIFgZR+E1wE5PQzWG/TBiXctwCOqOOErDB5b95jO2EntIhi8x5PO9Ef6jgis4QRsBIZiENDDeQHxFHCv4q+10TpyV+625O8TXkkcxl0g=="; };

    t2m = { hostNames = [ "t2m.cunat.cz" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBP9351NRVeQYvNV1bBbC5MX0iSmrXhVcBYMcn6AMo11U2zlOYRqBPzGLPjz9u31t4FxHNovxCrkFTqJY9zbsmTs="; };
    t2a = { hostNames = [ "t2a.cunat.cz" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu3itg4hn5e4KrnyoreAUN3RIbAcvqc7yWx5i6EWqAu"; };
    t4b = { hostNames = [ "t4b.cunat.cz" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/jE8c0lkc/DlK3R7A+zBr6j/lfEQrhqSD/YOEVs8za"; };

  };

}
