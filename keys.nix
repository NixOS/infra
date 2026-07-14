rec {
  age = {
    recipients = {
      hexa = [
        "age1yubikey1qwuegva8azwhjxvahxm59dfsyf7xhz3ulzexav2dkulq6vm958rlz2xxp9l"
        "age1yubikey1qtm7740epvw4ju2a53vy7jgs6nvfpz5mjq6vvzwf2ty04h6h7l7tqytgu5k"
      ];
    };
    groups = with age.recipients; {
      infra-core = ssh.groups.infra-core ++ hexa;
    };
  };

  ssh = {
    users = {
      arianvp = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHdERauixCGEk0oxLB+725k2M3McKHM0hjOjOWS+Dxdf arian@Mac"
      ];

      hydra-queue-runner = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdxl6gDS7h3oeBBja2RSBxeS51Kp44av8OAJPPJwuU/ hydra-queue-runner@rhea"
      ];

      vcunat = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4IJkFIVyImkfD4fM89ya+hy2ig8kUg09PCdjB5rS82akFoucYZSYMG41ZrlMT5LAikIgWusBzpO5bBkqxqcYqaYK/VF06zVBk3kF1pAIoitst9z0PLXY8/N+bFJg6oT7p6EWGRvFggUviSTTvJFMNUdDgEpsLqLp8+IYXjfM3Cz6+TQmyWQSockobRqgdILTjc1p2uxmNSzy2fElpZ0sKRPLNYG4SVPBPnOavs1KPOtyC1pIHOuz5A605gPLFXoWpX2lIK6atmGheiHxURDAX3pANVm+iMmnjteP0jEGU26/SPqgVP3OxdcryHxL3WnSJGtTnycoa30qP/Edmy9vB"
      ];

      hexa = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAWQRR7dspgQ6kCwyFnoVlgmmPR4iWL1+nvq6a5ad2Ug hexa@gaia"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFSpdtIxIBFtd7TLrmIPmIu5uemAFJx4sNslRsJXfFxr hexa@helix"
      ];

      mic92 = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEVSsc5mlP8aWiUVwWWM3gKlB5LHVpmKSifnDyox/BnVAAAABHNzaDo= yubikey1"
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCsjXKHCkpQT4LhWIdT0vDM/E/3tw/4KHTQcdJhyqPSH0FnwC8mfP2N9oHYFa2isw538kArd5ZMo5DD1ujL5dLk= ssh@secretive.Joerg’s-Laptop.local"
      ];

      jfly = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIImw0Xc1buEQ9WOskyGGeg3QwdbU7DTUQBiu02fObDlm jfly"
      ];

      brianmcgee = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBKHHl5kgMDNQA/zqK+AzT4SO09rfAp+y/EeUC+Ow5XqyNid5lm6sgLGM+AqZDx0jOrMKWhd5lhzGDdtsSf0Y8g4= brian@saturn"
      ];

      janne = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM35Bq87SBWrEcoDqrZFOXyAmV/PJrSSu3hl3TdVvo4C janne"
      ];

      conni2461 = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPK/3rYhlIzoPCsPK38PMdK1ivqPaJgUqWwRtmxdKZrO ✏️"
      ];

      ericson2314 = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdof+fSLyz3FV5t/yE9LBk/hgR8iNfdz/DRigvh4pP6+E4VPpPKSeA0a8r4CLMWvy9ZZ3Gqa04NdJnMmo8gBSIlo87JPq66GnC5QmeDJX2NLlliSeNQqUQKJ2VVcsVerz8O/RvVfvU2MIdW8VExx/DxeZbMnwRcWfUC0nby0NotWGNeS3NOcWWQq9z4E0sDSJ+QXSIMXWSeMda5sBadUK+YERTLYE/+ZVUPiXkXCmnwuRFHpZsqlRVad+kgXsZIwNEPUEqmEablg2C0NjvEbs75Yu9WUXXPJNhwaFbVXaWUM8UWO/n39jMM8aepalZbMhdFh129cAH35SjzIYjHxTP"
      ];
    };

    groups = with ssh.users; {
      infra-core = arianvp ++ hexa ++ mic92 ++ vcunat;

      infra = ssh.groups.infra-core ++ jfly;

      ofborg = ssh.groups.infra-core ++ janne ++ conni2461;
    };

    machines = {
      # build/
      haumea = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBamzRwZmoLjBFoNruGSVJEahk02Ku7NrBOmqcRWxcPm";
      pluto = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzc6B1S4mp3T3oWZnqQDkDVWFBIzLtkgkdgstfYZ5d/";
      mimas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICzfTNppOS5b5IvZl1wqjGTUZE0D/o/MY8d7uKPWDvIp";
      titan = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDgz6s5Yho6/bjvrRDuJ2IewAZQaevAMOeMjVjMaw5e+";

      # builders/
      elated-minsky = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIvrJpd3aynfPVGGG/s7MtRFz/S6M4dtqvqKI3Da7O7+";
      goofy-hopcroft = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICTJEi+nQNd7hzNYN3cLBK/0JCkmwmyC1I+b5nMI7+dd";
      hopeful-rivest = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgjwpQaNAWdEdnk1YG7JWThM4xQdKNJ3h3arhF7+iFm";
      sleepy-brown = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOh4/3m7o6H3J5QG711aJdlSUVvlC8yW6KoqAES3Fy6I";

      # macs/
      eager-heisenberg = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBp9NStfEPu7HdeK8f2KEnynyirjG9BUk+6w2SgJtQyS";
      enormous-catfish = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMlg7NXxeG5L3s0YqSQIsqVG0MTyvyWDHUyYEfFPazLe";
      growing-jennet = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAQGthkSSOnhxrIUCMlRQz8FOo5Y5Nk9f9WnVLNeRJpm";
      intense-heron = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICeSgOe/cr1yVAJOl30t3AZOLtvzeQa5rnrHGceKeBue";
      kind-lumiere = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFoqn1AAcOqtG65milpBtWVXP5VcBmTUSMGNfJzPwW8Q";
      maximum-snail = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEs+fK4hH8UKo+Pa7u1VYltkMufBHHH5uC93RQ2S6Xy9";
      norwegian-blue = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDQ6Cjvoq5VBYfXl6ZV/ijQ1q4UxbWRYYfkXe0rzmJjf";
      sweeping-filly = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6b/coXQEcFZW1eG4zFyCMCF0mZFahqmadz6Gk9DWMF";
    };
  };
}
