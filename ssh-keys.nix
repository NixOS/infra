rec {
  arianvp-mac = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHdERauixCGEk0oxLB+725k2M3McKHM0hjOjOWS+Dxdf arian@Mac";

  eelco = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAnI5L6oCgFyvEesL04LnbnH1TBhegq1Yery6TNlIRAA edolstra@gmail.com";

  hydra-queue-runner = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyM48VC5fpjJssLI8uolFscP4/iEoMHfkPoT9R3iE3OEjadmwa1XCAiXUoa7HSshw79SgPKF2KbGBPEVCascdAcErZKGHeHUzxj7v3IsNjObouUOBbJfpN4DR7RQT28PZRsh3TvTWjWnA9vIrSY/BvAK1uezFRuObvatqAPMrw4c0DK+JuGuCNkKDGHLXNSxYBc5Pmr1oSU7/BDiHVjjyLIsAMIc20+q8SjWswKqL1mY193mN7FpUMBtZrd0Za9fMFRII9AofEIDTOayvOZM6+/1dwRWZXM6jhE6kaPPF++yromHvDPBnd6FfwODKLvSF9BkA3pO5CqrD8zs7ETmrV hydra-queue-runner@chef";

  zimbatm = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOuiDoBOxgyer8vGcfAIbE6TC4n4jo8lhG9l01iJ0bZz zimbatm";

  vcunat = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4IJkFIVyImkfD4fM89ya+hy2ig8kUg09PCdjB5rS82akFoucYZSYMG41ZrlMT5LAikIgWusBzpO5bBkqxqcYqaYK/VF06zVBk3kF1pAIoitst9z0PLXY8/N+bFJg6oT7p6EWGRvFggUviSTTvJFMNUdDgEpsLqLp8+IYXjfM3Cz6+TQmyWQSockobRqgdILTjc1p2uxmNSzy2fElpZ0sKRPLNYG4SVPBPnOavs1KPOtyC1pIHOuz5A605gPLFXoWpX2lIK6atmGheiHxURDAX3pANVm+iMmnjteP0jEGU26/SPqgVP3OxdcryHxL3WnSJGtTnycoa30qP/Edmy9vB";

  hexa-gaia = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAWQRR7dspgQ6kCwyFnoVlgmmPR4iWL1+nvq6a5ad2Ug hexa@gaia";
  hexa-helix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFSpdtIxIBFtd7TLrmIPmIu5uemAFJx4sNslRsJXfFxr hexa@helix";

  mic92-turingmachine = "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIEVSsc5mlP8aWiUVwWWM3gKlB5LHVpmKSifnDyox/BnVAAAABHNzaDo= yubikey1";
  mic92-evo = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCsjXKHCkpQT4LhWIdT0vDM/E/3tw/4KHTQcdJhyqPSH0FnwC8mfP2N9oHYFa2isw538kArd5ZMo5DD1ujL5dLk= ssh@secretive.Joerg’s-Laptop.local";

  jfly = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIImw0Xc1buEQ9WOskyGGeg3QwdbU7DTUQBiu02fObDlm jfly";

  infra-core = [
    hexa-gaia
    hexa-helix
    vcunat
    zimbatm
    mic92-turingmachine
    mic92-evo
    arianvp-mac
  ];

  infra = infra-core ++ [ jfly ];

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
    sweeping-filly = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6b/coXQEcFZW1eG4zFyCMCF0mZFahqmadz6Gk9DWMF";
  };
}
