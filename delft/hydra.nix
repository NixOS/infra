{ config, lib, pkgs, ... }:

with lib;

let
  hydraSrc = ../../hydra;
  hydra = (import (hydraSrc + "/release.nix") {}).build.x86_64-linux;
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
      max_servers 50

      enable_google_login = 1
      google_client_id = 816926039128-ia4s4rsqrq998rsevce7i09mo6a4nffg.apps.googleusercontent.com

      store_uri = s3://nix-cache?secret-key=/var/lib/hydra/queue-runner/keys/cache.nixos.org-1/secret&write-nar-listing=1&ls-compression=br&log-compression=br
      server_store_uri = https://cache.nixos.org?local-nar-cache=${narCache}
      binary_cache_public_uri = https://cache.nixos.org

      <hipchat>
        jobs = (hydra|nixops):.*:.*
        room = 182482
        token = ${builtins.readFile ./hipchat-lb-token}
      </hipchat>

      <Plugin::Session>
        cache_size = 32m
      </Plugin::Session>

      # patchelf:master:3
      xxx-jobset-repeats = nixos:reproducibility:1

      nar_buffer_size = 12884901888

      upload_logs_to_binary_cache = true

      # FIXME: Cloudfront messes up CORS
      #log_prefix = https://cache.nixos.org/

      log_prefix = https://nix-cache.s3.amazonaws.com/
    '';

  system.activationScripts.createNarCache =
    ''
      mkdir -p /var/cache/hydra -m 0755
      chown hydra.hydra /var/cache/hydra
      mkdir -p ${narCache} -m 0775
      chown hydra.hydra ${narCache}
    '';

  users.extraUsers.hydra.home = mkForce "/home/hydra";

  systemd.services.hydra-queue-runner.restartIfChanged = false;
  systemd.services.hydra-queue-runner.wantedBy = mkForce [];
  systemd.services.hydra-queue-runner.requires = mkForce [];

  systemd.services.hydra-evaluator.environment.GC_INITIAL_HEAP_SIZE = "4G";

  programs.ssh.extraConfig = mkAfter
    ''
      ServerAliveInterval 120
      TCPKeepAlive yes

      Host mac1
      Hostname 213.125.166.74
      Port 6001
      Compression yes

      Host mac2
      Hostname 213.125.166.74
      Port 6002
      Compression yes

      Host mac3
      Hostname 213.125.166.74
      Port 6003
      Compression yes

      Host mac4
      Hostname 213.125.166.74
      Port 6004
      Compression yes

      Host mac5
      Hostname 213.125.166.74
      Port 6005
      Compression yes

      Host mac6
      Hostname 213.125.166.74
      Port 6006
      Compression yes

      Host mac7
      Hostname 213.125.166.74
      Port 6007
      Compression yes

      Host mac8
      Hostname 213.125.166.74
      Port 6008
      Compression yes

      Host mac9
      Hostname 213.125.166.74
      Port 6009
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

      Host packet-t2a-1
      Hostname 147.75.65.54
      Compression yes
    '';

  services.openssh.knownHosts =
    [
      { hostNames = [ "83.87.124.39" ]; publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDVTkY4tQ6V29XTW1aKtoFJoF4uyaEy0fms3HqmI56av8UCg3MN5G6CL6EDIvbe46mBsI3++V3uGiOr0pLPbM9fkWC92LYGk5f7fNvCoy9bvuZy5bHwFQ5b5S9IJ1o3yDlCToc9CppmPVbFMMMLgKF06pQiGBeMCUG/VoCfiUBq+UgEGhAifWcuWIOGmdua6clljH5Dcc+7S0HTLoVtrxmPPXBVZUvW+lgAJTM6FXYIZiIqMSC2uZHGVstY87nPcZFXIbzhlYQqxx5H0um2bL3mbS7vdKhSsIWWaUZeck9ghNyUV1fVRLUhuXkQHe/8Z58cAhTv5dDd42YLB0fgjETV"; }
      { hostNames = [ "[213.125.166.74]:6001" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBP7xnlcQ4Ymnl+Ewz+6Kmhz72bqBay6KydBx4wsScIYReX8QiqvPH2ozeyl6yQ8rsYC75Z/aPwNzLoemMBmaPzE= "; }
      { hostNames = [ "[213.125.166.74]:6002" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFw1hBw7UtCIkOP/QOU/oMNqETnm0bQYl3BQsGN9u9vW9ty1MjV/DP/rtT056wg4ZpvxwoSlW17QM5ddKke60RY= "; }
      { hostNames = [ "[213.125.166.74]:6003" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNReX6n69253+v9C4JNK6ARQ/eAM1z5IyuR4cpZOJ/XVY72voEx7Q/GsbmGfmejnVdj54OYsOS5eYBUFim65IUM= "; }
      { hostNames = [ "[213.125.166.74]:6004" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBD2XQ+bjuEfNdFnpCcusD6JW5jT5qdepo2vKb4W5Pt9DdxwNuaIbzWNaiTmvip2lF+43oM274CeE7Do3XdeO1S0= "; }
      { hostNames = [ "[213.125.166.74]:6005" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNMoN47gtth42f4MCduo5QclW9dyW+R8GEQDb5m+w3h2soBtDvLLSokYemmyn/3vkbuswQcA8ZthsiqkHJS3pq8= "; }
      { hostNames = [ "[213.125.166.74]:6006" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBJJPXzpnYgA7Y7inIqVG9McCy1Zrqnu6UfJO8etTKegwfyKxMtIwWWBqweNVhfygZlUKJ1y99MwHWE5VDKTUhZk= "; }
      { hostNames = [ "[213.125.166.74]:6007" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCa4WqiBgZJT9iKb1mKhc4f2LzapOX0SW5uq0bKtvpbzNwG6UVVeKv+/p4QWLadykRVpssoFNpLFoPF73J+duKQ= "; }
      { hostNames = [ "[213.125.166.74]:6008" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBP5ip9sIKANIVux/aXG4lpUmlaMKqT+GgVEshJxC5ddi2glXkmo6v+VrRs3kTixat1jUHzaYM3mPU90JFJOrg+U= "; }
      { hostNames = [ "[213.125.166.74]:6009" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBOa5gL7S5MBSsTBRh0eeJKK7qPmJj2o3cfI7bZBc9VQIcjHEkETxc7Bv9ap0rkThU2Skzx95YLyndq954cONH/Q= "; }
      { hostNames = [ "208.78.106.251" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBKrwg2592DfDUG1U0LZxJcBaT35YfEsuKo4helEAzeoujvzOo4DIaBrTCX7+LxcYZlGoi4WvsnwxUG11GY12l2A="; }
      { hostNames = [ "208.78.106.252" ]; publicKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBLV1p6f6Rk3rKwNJbcqvG68wjfT3wPcJfChc1LFU9A3tTFslUDr47FHLmT+FTr+ChkoqD6Gsl+jtSnvkYnTlpGY="; }
      { hostNames = [ "hydra.ewi.tudelft.nl" "131.180.119.69" ]; publicKey = "ssh-dss AAAAB3NzaC1kc3MAAACBAJBHaP+SAMm/eTYciPpQi8x5NULRV8D9/xQPd/SU7s+mQP/TlvLCmgpuHudZMrLgUDWjKclFQThBuhElCvZzHmBcWPP64wzlZdxsizub9525FPAMnhbK5bqQHgji+ilXGTwv+ZvwEC1LJEQz4H5jgXlIgwNzvED4xo8IyLTxKw6TAAAAFQCQE8H+w6xYFMiDLK7tpGaweLj04QAAAIAuES8pfxge4UrDAnKyYEN/IZwTMLznAHoldaa+E+8KYVs7QnhMztJr9kIZWOJOsmEcQ/1SwFJPSU04FbJ25Z25B8jUG6UqMYidiQnzjHqKc29AYo3ZS9xWJ62VS7cW+UeC4zUFMA8jtlaVCfU95uharu+lzM4SecC9+35ObWpn1wAAAIAzgtOQhC7udZJPnvqc4L6AATMoaAQQ3x95nher6oyL3N6Yi6+Sy10v3u5c5uccaDQ/oVjQHBeaFnciNXYTqF0z4u3MmsQ+RtnElJ2+rqqxzvuOUkCms5yNdNq+Ag79MVd5ESlgowtivtZ+p8aH7cIJFab+YkfUpTrZnGDrUl/kEQ=="; }
      { hostNames = [ "ike.ewi.tudelft.nl" "131.180.119.70" ]; publicKey = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGNzlom/R/lJ0TZb2HLm19V+BoifFoENHocIJ4MiV9FQCOUlLLQh7kZMKtzVJdM+n1q1BqLp6bll6U7PsLUKAg+rgDU2saHd8ScaeZqhdmWpO4lMMxpNreAETsY1txpSatT4aHvjJMTlT1pmaLiqfhCenqxaqeH3/3XPkVfK48Nk+mo8w=="; }
      { hostNames = [ "kenny.ewi.tudelft.nl" "131.180.119.71" ]; publicKey = "ssh-dss AAAAB3NzaC1kc3MAAACBANmEz1UzFCfab/a/VjWFr/mrwB/trcMPXg15U6vy6iprg34vKbanefX0BJOyBUdueNenSAcuC18mDH/aYrCb7Y5CyhLQH8w7YaTpehbpMIS4SJGC3hRd4LSE7mYBUQf396Syp5coA0CHZJZ6lhLYspZCHDonm1vAfVyMqJOSubPlAAAAFQCNFpbZrLGfyPcWss7e+iF/i/xszwAAAIBONlTGHQpDNadffT9NQ3l8hFe8P9MJvRIUW1q/VEzRRBcbBWQnYh35YXMYPyrZaXaGILv6ma462PUu23VBoF9/twxMRBkKEuWfe1c+YM0w7wd6BA5L99GMhQGsy8ahSyD3FN3sW9kqqzryYt0KgCqCTDo/HAp51UYCeXuflABv8QAAAIB3lV9cSaUrso1jMhkPJU+oIuUjGyd+8stWGp2lXc0+ccud+tkx9rpTr2oZOcM6/2NKSvz6XXQ+9l/iTQxSIlrJpi337Hpv4qkjB2R0cID+xxKT5Y9NLxMtaEipwvpAX4GRtpzK0KJB9x4CM8jiF1SIRPQkBKZme8XPq8B3kdCEIA=="; }
      { hostNames = [ "kyle.ewi.tudelft.nl" "131.180.119.72" ]; publicKey = "ssh-dss AAAAB3NzaC1kc3MAAACBAJtmR7tVnalxWtoAc7Xewomickd5qB4Zc7U/+P3OAweqdmYB9uzJPOIfKcuw3o02du1exalgtcUKeqGCPWB8uAwScDB/sbMuN9vxIoogYsT4aZFlgzUM9Nvan9Q4jJ9fi9wBD0KJWSTf3WSQm18p/NQ7hwXqHA5ry2HFCrP005oBAAAAFQDRK3bgyIpLB0gQnRwSK9RScmekvQAAAIEAhZVMQBUW13XAMHQxPVMug9kW6uAp/Dk/nm124KIeeCDgV+SMCSntwdE7opz+CfR2GbMVOKYRlx8TJJhuI4ubPYT0HrcmP9snAgidwXME8DZCdxfdz7c04ggTrww3Z/yc0dS5rDv7OF3dO/44WXFzOwWV8rV6ihf4lY+WrhDeITwAAACBAIbOt7wn5moefey3ZIZQ3Ls7neP69b35oYpAjtb/8rOMMe+umg2jACMP/G/pGn77cZ8XTN6eVA6oJTSKAzJQhxQBQeBMk96cJHKOtstAMTW++5PK0x0iMehn/NMxVf905oTlTNPyNuf2xOK3u0MtzFAn03qWFFeIXT8db2NKckvs"; }
      { hostNames = [ "lucifer.ewi.tudelft.nl" "131.180.119.73" ]; publicKey = "ssh-dss AAAAB3NzaC1kc3MAAACBAPrrqKNWZX/3uDOpxrIiiw25uiyWdoxw6KBqLB073Pa6wCttMEzNMHRXYZ8DeKYu4wme0b0siST+sXHDAiuYfyeTpr0IIQSoSCmVkEbV+qddSQG3j1nsQS/UoOa9+NLeT1A/VjvHLY+84OfCj2cIsH8K5pq2kRgzO8mPMCiBqIvVAAAAFQDM7cuqhTdSz19NPFFTLsxumhDsywAAAIBEnvmdidhrWcyJ8PFn65IaRnU5wrxbfza/+yWXQzsEo83ROIJn9rsa497fm1ZIEddD0GjJcQDYhHRoS1M3Yd4NuPSd4677FnRZwU1oVC+KvjslOfdaWCrSpBZ9Ku6vc8/27gF+HgLdG2mXIqkKMbtEiREOB1RD1C3+1fJ2o2BjjgAAAIEA+uPTp8aZIu9o/E0jyIDQXT6LZ37jTSK2M2LJw9kT1GWpJfLjnntUfvAUmJOoWAaEKuy2abafHLPrefnqKzIWy8OKPUzfwW+Kqre6SUNyKxeEXN+rdqR7LIZhYweoX8tHxbNCf2HkwJvZQw7lx9ACfeOkA5N56krb7kZqtCP6N6I="; }
      { hostNames = [ "stan.ewi.tudelft.nl" "131.180.119.74" ]; publicKey = "ssh-dss AAAAB3NzaC1kc3MAAACBAL0SlYpGjDjPKrLIwoltYHHTYo/d6Ct2FQZKh4ltKOszWPYYAbs/YNSm2eFkvj0CGc3aastFuebz6+pRfvGMvqi4q6IoHwVvOkbWMadyuqrWIO+Z1YemZP/GAG69pLy+UyoydiSI83ycwPe4YARAU/cpBMNKJZbSxyrO80XatmtRAAAAFQC291WK+9M8+zI4KAtk6EqX0vqQ1QAAAIBd1YgRfdfRdu60BpR+3/YMbSYZMjRLFPyoSgmEQR2TtKfqsuKTsTREzB20iMgFlhEWb6C4r5y6jYDU85OOnvpf7zne22j6bKFDIiAbgsjUFHK1EB7+TBltf5yqq0FyNOy/PnLqVzOeGaUeCOc3Ris71Lxkm60oVF4mjut2d2UJ6AAAAIByuCH1bIIRb4za4yiiFQUz2CBX1XHhBn/h/LhNMLuyCTciG6tkppGBAgq5rWrNhjaEc7dIFgZR+E1wE5PQzWG/TBiXctwCOqOOErDB5b95jO2EntIhi8x5PO9Ef6jgis4QRsBIZiENDDeQHxFHCv4q+10TpyV+625O8TXkkcxl0g=="; }
      { hostNames = [ "wendy.ewi.tudelft.nl" "131.180.119.77" ]; publicKey = "ssh-dss AAAAB3NzaC1kc3MAAACBAIDHVZ/xtcBsNHJ6qYxa3f1RX5k+SaRwgemCfIBSOgL8AGnsvD+OomlGg/eDhJU60AzFSZBQjKtrgRYWmAnzqSMOtfb9IIT5JfG5h/27LVjaaq29Mv+PcDpuPLuFNW3G50hDD1gA0hQhrZdZBkBv9MBaJgizFUjV9tb8KZIRS+MDAAAAFQC8YJViwihyk0oIHOgBfBifiTku6QAAAIBHadEeonXcbDWH6Q5esR1IU7dFMw/zS/wg9IgH0b7lRZBkyVkS0yxfJ7r8swCQ0Loh9dvLtbHLXMlegNfEFv3nbmZqE4copO/2wOM7SqhJRykByMFEhY28t1O1M4rYmzqXs92VUtc5xiTR/lv93C05KSkOl7rUfw43jsWgQAzIkgAAAIB3s4ntqW4H0TdNJFOpaVq1wgRJi768BAVq7MnuIKpFfjGiO7P1Wtk+6/8rzP3gx4cFELZWfJiDHZO5pJE2UGtx5yioQihg4nnZPxTw4FJS/Olf15S2CB/EsYgn9NlUAfOR29ApwasHAy8uP89iOv94cP3YMnWoSi0jkq8iSrSy7Q=="; }

      # packet-t2-4
      { hostNames = [ "147.75.98.145" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIABlJeKJ2B5mgK8TujC3FZ7geAOzQFUDJpay6a8Utdg6"; }

      # packet-t2a-1
      { hostNames = [ "147.75.65.54" ]; publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINPipUJuE/vHgrakfIBp+mt7iS3DlMlecRdI/hleGm1W"; }
    ];

}
