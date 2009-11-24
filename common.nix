{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.emacs pkgs.subversion ];

  services.sshd.enable = true;

  boot.postBootCommands =
    ''
      echo 60 > /proc/sys/kernel/panic
    '';
}
