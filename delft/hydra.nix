{ config, lib, pkgs, ... }:

with lib;

let
  hydraSrc = ../../hydra;
  hydra = (import (hydraSrc + "/release.nix") { nixpkgs = pkgs.path; }).build.x86_64-linux;
  narCache = "/var/cache/hydra/nar-cache";
in

{
  imports =
    [ (hydraSrc + "/hydra-module.nix")
    ];

  users.extraUsers.hydra.openssh.authorizedKeys.keys =
    with import ../ssh-keys.nix; [ eelco rob ];
  users.extraUsers.hydra-www.openssh.authorizedKeys.keys =
    with import ../ssh-keys.nix; [ eelco rob ];
  users.extraUsers.hydra-queue-runner.openssh.authorizedKeys.keys =
    with import ../ssh-keys.nix; [ eelco rob ];

  services.hydra-dev.enable = true;
  services.hydra-dev.package = hydra;
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

      store_uri = s3://nix-cache?secret-key=/var/lib/hydra/queue-runner/keys/cache.nixos.org-1/secret&write-nar-listing=1&ls-compression=br&log-compression=br
      server_store_uri = https://cache.nixos.org?local-nar-cache=${narCache}
      binary_cache_public_uri = https://cache.nixos.org

      #<hipchat>
      #  jobs = (hydra|nixops):.*:.*
      #  room = 182482
      #  token = ${builtins.readFile ./hipchat-lb-token}
      #</hipchat>

      <Plugin::Session>
        cache_size = 32m
      </Plugin::Session>

      # patchelf:master:3
      xxx-jobset-repeats = nixos:reproducibility:1

      nar_buffer_size = ${let gb = 10; in toString (gb * 1024 * 1024 * 1024)}

      upload_logs_to_binary_cache = true

      # FIXME: Cloudfront messes up CORS
      #log_prefix = https://cache.nixos.org/

      log_prefix = https://nix-cache.s3.amazonaws.com/

      evaluator_initial_heap_size = ${let gb = 20; in toString (gb * 1024 * 1024 * 1024)}

      max_concurrent_evals = 2
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

      Host macstadium1
      Hostname 208.78.106.251
      Compression yes

      Host macstadium2
      Hostname 208.78.106.252
      Compression yes

      Host packet-t2-4
      Hostname 147.75.98.145
      Compression yes

      Host packet-t2a-2
      Hostname 147.75.79.198
      Compression yes

      Host packet-t2a-3
      Hostname 147.75.198.170
      Compression yes

      Host packet-epyc-1
      Hostname 147.75.198.47
      Compression yes

      Host packet-t2a5-qc-centriq-1
      Hostname 147.75.74.238
      Compression yes

      Host packet-c2-large-arm
      Hostname 147.75.107.234
      Compression yes
  '';

  services.openssh.knownHosts =
    [
      { hostNames = [ "83.87.124.39" ]; publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVTkY4tQ6V29XTW1aKtoFJoF4uyaEy0fms3HqmI56av8UCg3MN5G6CL6EDIvbe46mBsI3++V3uGiOr0pLPbM9fkWC92LYGk5f7fNvCoy9bvuZy5bHwFQ5b5S9IJ1o3yDlCToc9CppmPVbFMMMLgKF06pQiGBeMCUG/VoCfiUBq+UgEGhAifWcuWIOGmdua6clljH5Dcc+7S0HTLoVtrxmPPXBVZUvW+lgAJTM6FXYIZiIqMSC2uZHGVstY87nPcZFXIbzhlYQqxx5H0um2bL3mbS7vdKhSsIWWaUZeck9ghNyUV1fVRLUhuXkQHe/8Z58cAhTv5dDd42YLB0fgjETV"; }

      # (for i in $(seq 6000 6010); do ssh-keyscan -t ssh-ed25519 -p $i 37.153.215.191 2> /dev/null; done) | sed -e 's/^/      { hostNames = [ "/' -e 's/ ssh/" ]; publicKey = "ssh/' -e 's/$/"; }/'; echo
      { hostNames = [ "[10.254.2.2]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKJSLxndBO2SqMklTT4dWsv54CtKVMHDOhXl7v1tC38v"; }
      { hostNames = [ "[10.254.2.3]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKdzP9scGjJ31wwDJdcXcO4+wayvrHkFAefP/0I7UB0r"; }
      { hostNames = [ "[10.254.2.4]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAaK44azT14aWHTE2fMYJFeJBTg1hQg2n2KAEgu8qlII"; }
      { hostNames = [ "[10.254.2.5]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgJ2Mh0vkrBcIBcWgFoEPsYG9dyPOAUgL0GOhhBoRcD"; }
      { hostNames = [ "[10.254.2.6]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICyjTqJsNioHUP0HMmGVfDpej9dCIQH0Bdn5aNbe8oYU"; }
      { hostNames = [ "[10.254.2.7]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKjy5mXHUHqGO+lzeyj09iuADIDtcQtnBtwiPCmV/UBq"; }
      { hostNames = [ "[10.254.2.8]:2200" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHJF0dXSTvZwWtPjN/iUBp2A5pHCPuOUVOvBkjXw+Eu"; }

      { hostNames = [ "208.78.106.251" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBKrwg2592DfDUG1U0LZxJcBaT35YfEsuKo4helEAzeoujvzOo4DIaBrTCX7+LxcYZlGoi4WvsnwxUG11GY12l2A="; }
      { hostNames = [ "208.78.106.252" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLV1p6f6Rk3rKwNJbcqvG68wjfT3wPcJfChc1LFU9A3tTFslUDr47FHLmT+FTr+ChkoqD6Gsl+jtSnvkYnTlpGY="; }
      { hostNames = [ "hydra.ewi.tudelft.nl" "131.180.119.69" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIS6QYRKqOt9zfvFej4WWaswLE8Mhq7dOk8enWi/AzoK"; }
      { hostNames = [ "ike.ewi.tudelft.nl" "131.180.119.70" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDTj/aLPNA+D3ysNPzGMRGVqfu0BzRx2k0LJJRqeN+S+"; }
      { hostNames = [ "kenny.ewi.tudelft.nl" "131.180.119.71" ]; publicKey = "ssh-dss AAAAB3NzaC1kc3MAAACBANmEz1UzFCfab/a/VjWFr/mrwB/trcMPXg15U6vy6iprg34vKbanefX0BJOyBUdueNenSAcuC18mDH/aYrCb7Y5CyhLQH8w7YaTpehbpMIS4SJGC3hRd4LSE7mYBUQf396Syp5coA0CHZJZ6lhLYspZCHDonm1vAfVyMqJOSubPlAAAAFQCNFpbZrLGfyPcWss7e+iF/i/xszwAAAIBONlTGHQpDNadffT9NQ3l8hFe8P9MJvRIUW1q/VEzRRBcbBWQnYh35YXMYPyrZaXaGILv6ma462PUu23VBoF9/twxMRBkKEuWfe1c+YM0w7wd6BA5L99GMhQGsy8ahSyD3FN3sW9kqqzryYt0KgCqCTDo/HAp51UYCeXuflABv8QAAAIB3lV9cSaUrso1jMhkPJU+oIuUjGyd+8stWGp2lXc0+ccud+tkx9rpTr2oZOcM6/2NKSvz6XXQ+9l/iTQxSIlrJpi337Hpv4qkjB2R0cID+xxKT5Y9NLxMtaEipwvpAX4GRtpzK0KJB9x4CM8jiF1SIRPQkBKZme8XPq8B3kdCEIA=="; }
      { hostNames = [ "kyle.ewi.tudelft.nl" "131.180.119.72" ]; publicKey = "ssh-dss AAAAB3NzaC1kc3MAAACBAJtmR7tVnalxWtoAc7Xewomickd5qB4Zc7U/+P3OAweqdmYB9uzJPOIfKcuw3o02du1exalgtcUKeqGCPWB8uAwScDB/sbMuN9vxIoogYsT4aZFlgzUM9Nvan9Q4jJ9fi9wBD0KJWSTf3WSQm18p/NQ7hwXqHA5ry2HFCrP005oBAAAAFQDRK3bgyIpLB0gQnRwSK9RScmekvQAAAIEAhZVMQBUW13XAMHQxPVMug9kW6uAp/Dk/nm124KIeeCDgV+SMCSntwdE7opz+CfR2GbMVOKYRlx8TJJhuI4ubPYT0HrcmP9snAgidwXME8DZCdxfdz7c04ggTrww3Z/yc0dS5rDv7OF3dO/44WXFzOwWV8rV6ihf4lY+WrhDeITwAAACBAIbOt7wn5moefey3ZIZQ3Ls7neP69b35oYpAjtb/8rOMMe+umg2jACMP/G/pGn77cZ8XTN6eVA6oJTSKAzJQhxQBQeBMk96cJHKOtstAMTW++5PK0x0iMehn/NMxVf905oTlTNPyNuf2xOK3u0MtzFAn03qWFFeIXT8db2NKckvs"; }
      { hostNames = [ "lucifer.ewi.tudelft.nl" "131.180.119.73" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDz6dxwVdxPpwtjO3wA9nMp62qFLGy2ETpSQ6JWTOs5P"; }
      { hostNames = [ "stan.ewi.tudelft.nl" "131.180.119.74" ]; publicKey = "ssh-dss AAAAB3NzaC1kc3MAAACBAL0SlYpGjDjPKrLIwoltYHHTYo/d6Ct2FQZKh4ltKOszWPYYAbs/YNSm2eFkvj0CGc3aastFuebz6+pRfvGMvqi4q6IoHwVvOkbWMadyuqrWIO+Z1YemZP/GAG69pLy+UyoydiSI83ycwPe4YARAU/cpBMNKJZbSxyrO80XatmtRAAAAFQC291WK+9M8+zI4KAtk6EqX0vqQ1QAAAIBd1YgRfdfRdu60BpR+3/YMbSYZMjRLFPyoSgmEQR2TtKfqsuKTsTREzB20iMgFlhEWb6C4r5y6jYDU85OOnvpf7zne22j6bKFDIiAbgsjUFHK1EB7+TBltf5yqq0FyNOy/PnLqVzOeGaUeCOc3Ris71Lxkm60oVF4mjut2d2UJ6AAAAIByuCH1bIIRb4za4yiiFQUz2CBX1XHhBn/h/LhNMLuyCTciG6tkppGBAgq5rWrNhjaEc7dIFgZR+E1wE5PQzWG/TBiXctwCOqOOErDB5b95jO2EntIhi8x5PO9Ef6jgis4QRsBIZiENDDeQHxFHCv4q+10TpyV+625O8TXkkcxl0g=="; }
      { hostNames = [ "wendy.ewi.tudelft.nl" "131.180.119.77" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQOW9V+azndhOiWApltwo7Khnc5/MNEAW8Rf5J/NyBx"; }

      # packet-t2-4
      { hostNames = [ "147.75.98.145" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIABlJeKJ2B5mgK8TujC3FZ7geAOzQFUDJpay6a8Utdg6"; }

      # packet-t2a-2
      { hostNames = [ "147.75.79.198" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDCo+z5d8C6SpCyvC8KAPMAcMEtd5J74tRsk+7sm2KgD"; }

      # packet-t2a-3
      { hostNames = [ "147.75.198.170" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPieDw5aeaN88HMIye2t4tL6DBqgJwQbXH0PzPd0HOVl"; }

      # packet-t2a5-qc-centriq-1
      { hostNames = [ "147.75.74.238" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJTGvykBvR6l4d0ssReNLMV2qVV+TKNUrU22OOix//qE"; }

      # packet-c2-large-arm
      { hostNames = [ "147.75.107.234" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsY9skBvQx3mMFrMyR2zwK50OMEu5Xzw4tMLBH4Nzum"; }

      # packet-epyc-1
      { hostNames = [ "147.75.198.47" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAt76Jw/xXqvYcrNZSa+BEfKfLCFyvY50LZJuGBWtJwx"; }

      { hostNames = [ "t2m.cunat.cz" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBP9351NRVeQYvNV1bBbC5MX0iSmrXhVcBYMcn6AMo11U2zlOYRqBPzGLPjz9u31t4FxHNovxCrkFTqJY9zbsmTs="; }
      { hostNames = [ "t2a.cunat.cz" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIu3itg4hn5e4KrnyoreAUN3RIbAcvqc7yWx5i6EWqAu"; }
      { hostNames = [ "t4a.cunat.cz" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILXgOInIZ+1DdWDeXBO1ILtlM53ZrYOtrBlfZ7dIzCyu"; }
      { hostNames = [ "t4b.cunat.cz" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC/jE8c0lkc/DlK3R7A+zBr6j/lfEQrhqSD/YOEVs8za"; }

    ];

}
