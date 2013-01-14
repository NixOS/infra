{ config, pkgs, ... }:

with pkgs.lib;

{
  users.extraUsers.root.openssh.authorizedKeys.keys =
    [ # ~/.ssh/id_mass_update
      "ssh-dss AAAAB3NzaC1kc3MAAACBAN/f/VlDwxI0T51Kqen4WLz0ittuJFAgPZ6VwbwPPyHRpmKY/m5Zd2nycY8zDTDF1JJGlFpDC3wsoOlaYr4/AlJvRy/0SUvlnDcocXHs1BM1ZLWV2MdUuG6dCHNUYDsQat8bKm4YdjLmfL1p/PKpKS83+0S59u1PCkPWsoL0Wqc7AAAAFQCU4FSXrHs9GHEKuXQ2zpmsKcx2kwAAAIB40t8aJlEipcDtLPax3wfPxqAtbzDsYPuYrX5VF48tdbH4f/kZPm1qKaU7vq+m5n0uuT3mxsBFzuQpDcPhL7ZXJJEHRDMJgvq3dOCk0ejrXTTdnYHDMWUdC9S2f8kYTJ0lf7Jwro5R97PsTpsjfDRGLWoXUfpF6NARANQ0q+tM3wAAAIA14dh6XTX2NBsh+Cew8YYSX5ZK76zNREEbXxuzecXuP2VP14ZR3fMLXI201QyWP+U1Kj8QsS1v2XQ2MtNnXW3HOCb5C0L2Qs0AIV5YQ+UhXUen2RgA8tITUBBV6hLvdhnrmZ8Odrmf0+iAGXBxTgXwpWqW6X9W3CbXyA1Ncs0ZSQ== root@buildfarm"
    ];

  users.extraUsers.buildfarm =
    { description = "Hydra unprivileged build slave";
      home = "/home/buildfarm";
      createHome = true;
      useDefaultShell = true;
      openssh.authorizedKeys.keys = singleton "ssh-dss AAAAB3NzaC1kc3MAAACBAMHRjGSDaBp4Z30JF4S9ApabBCpdr57Ad0aD9oH2A/WEFnWYQSAzK4E/HHD2DV2XP1stNkZ1ks2v3F4Yu/veR+qVlUWbJW1RIIfuQgkG44K0R3C2qx4BAZUVYzju1NVCJbBOO6ipVY9cfmpokV52HZFhP/2HocTNLoav3F0AsbbJAAAAFQDaJiQdpJBEa4Wr5FfVl1kYqmQZJwAAAIEAwbern5XL+SNIMa+sJ3CBhrWyYExYWiUbdmhQEfyEAUmoPsEr1qpb+0WREic9Nrxz48QWZDK5xMvzZyQEkuAMJUBWcdm12rME7WMvg7OZGr9DADjAtfMfj3Ui2XvOuQ3ia/OTsMGkQTDWnkOM9Ni128SNSl9urFBlXATdGvo+468AAACBAK8s6LddhhkRqsF/l/L2ooS8c8A1rTFWAOy3/sgXFNvMyS/Mig2p966xRrRHr7Bc+H2SuKEE5WmLCXqymgxLHhrFU4zm/W/ej1yB1CAThd4xUfgJu4touJROjvcD1zzlmLeat0fp2k5mCuiLKcTKi0vxKWiiopF9nvBBK+7ODPC7 buildfarm@nixos";
    };

  boot.kernelPackages = pkgs.linuxPackages_3_2;

  boot.kernelModules = [ "coretemp" ];

  boot.supportedFilesystems = [ "nfs" ];

  boot.blacklistedKernelModules = [ "radeonfb" "radeon" ];

  boot.initrd.kernelModules = [ "ext4" ];

  environment.nix = pkgs.nixUnstable;

  environment.systemPackages =
    [ pkgs.emacs pkgs.subversion pkgs.sysstat pkgs.hdparm pkgs.sdparm # pkgs.lsiutil
      pkgs.htop pkgs.sqlite pkgs.iotop pkgs.lm_sensors pkgs.gitFull pkgs.hwloc
      pkgs.lsof pkgs.numactl pkgs.gcc
    ];

  services.sshd.enable = true;

  boot.postBootCommands =
    ''
      echo 60 > /proc/sys/kernel/panic
    '';

  nix.useChroot = true;

  nix.nrBuildUsers = 100;

  nix.extraOptions =
    ''
      build-cores = 0
    '';

  services.zabbixAgent.enable = true;
  services.zabbixAgent.server = "192.168.1.5,127.0.0.1,130.161.158.181";
  services.zabbixAgent.extraConfig =
    ''
      UserParameter=hardware.temp.cpu.average,shopt -s nullglob; cat /sys/devices/platform/coretemp.*/temp1_input /sys/bus/pci/drivers/k10temp/*/temp1_input < /dev/null | ${pkgs.perl}/bin/perl -e 'while (<>) { $n++; $sum += $_; }; print $sum / $n / 1000;'
      UserParameter=vm.memory.dirty,echo $((1024 * $(cat /proc/meminfo | sed 's/Dirty: *\([0-9]\+\) kB/\1/; t; d')))
      UserParameter=vm.memory.ksm.shared,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_shared)))
      UserParameter=vm.memory.ksm.sharing,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_sharing)))
      UserParameter=vm.memory.ksm.unshared,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_unshared)))
      UserParameter=vm.memory.ksm.volatile,echo -n $((4096 * $(cat /sys/kernel/mm/ksm/pages_volatile)))
    '';

  networking.defaultMailServer = {
    directDelivery = true;
    hostName = "smtp.tudelft.nl";
    domain = "st.ewi.tudelft.nl";
  };

  # Bump the open files limit so that non-root users can run NixOS VM
  # tests (Samba opens lot of files).
  security.pam.loginLimits =
    [ { domain = "*"; item = "nofile"; type = "-"; value = "16384"; }
    ];

  # Enable Kernel Samepage Merging (reduces memory footprint of VMs.
  boot.systemd.services."enable-ksm" =
    { description = "Enable Kernel Same-Page Merging";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      script =
        ''
          if [ -e /sys/kernel/mm/ksm ]; then
            echo 1 > /sys/kernel/mm/ksm/run
          fi
        '';
    };
}
