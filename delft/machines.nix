lib: with lib;

[ /* Physical machines. */

  /*
  { # APC UPS.
    hostName = "ups";
    ipAddress = "192.168.1.6";
    ethernetAddress = "00:c0:b7:5b:16:56";
  }
  */

  { # 8-core NixOS build machine.
    hostName = "kenny";
    ipAddress = "131.180.119.71"; # fe80::222:19ff:fe55:cc0d
    ethernetAddress = "00:22:19:55:cc:0d";
    systems = [ "x86_64-linux" "i686-linux" ];
    maxJobs = 8;
    speedFactor = 2;
    buildUser = "buildfarm";
  }

  { # 8-core NixOS build machine.
    hostName = "stan";
    ipAddress = "131.180.119.74"; # fe80::222:19ff:fe55:bf2e
    ethernetAddress = "00:22:19:55:bf:2e";
    systems = [ "x86_64-linux" "i686-linux" ];
    maxJobs = 8;
    speedFactor = 2;
    #buildUser = "buildfarm";
  }

  { # 8-core NixOS build machine.
    hostName = "kyle";
    ipAddress = "131.180.119.72"; # fe80::222:19ff:fe55:c118
    ethernetAddress = "00:22:19:55:c1:18";
    systems = [ "x86_64-linux" "i686-linux" ];
    maxJobs = 8;
    speedFactor = 2;
    buildUser = "buildfarm";
  }

  { # 64-bit Mac OS X build machine.
    hostName = "butters";
    ipAddress = "131.180.119.68";
    ethernetAddress = "00:24:36:f3:cd:c0";
    system = "x86_64-darwin";
    aliases = ["mac64-1"];
    maxJobs = 2;
    buildUser = "nix";
  }

  { # Old Hydra server, now build machine.
    hostName = "hydra";
    ipAddress = "131.180.119.69";
    ethernetAddress = "00:22:19:55:bf:24";
  }

  { # Old Hydra server, now build machine.
    hostName = "lucifer";
    ipAddress = "131.180.119.73"; # fe80::862b:2bff:fe0b:98f0
    ethernetAddress = "84:2b:2b:0b:98:f0";
  }

  { # 48-core NixOS web server (wiki), database server, build machine.
    hostName = "wendy";
    ipAddress = "131.180.119.77";
    ethernetAddress = "f0:4d:a2:40:1b:c0";
    systems = [ "x86_64-linux" ];
  }

  { # 48-core NixOS build machine.
    hostName = "ike";
    ipAddress = "131.180.119.70";
    ethernetAddress = "f0:4d:a2:40:1b:91";
    systems = [ "x86_64-linux" ];
  }

  /*
  { # 48-core NixOS build machine.
    hostName = "shelley";
    ipAddress = "192.168.1.28";
    ethernetAddress = "f0:4d:a2:40:10:6c";
    systems = [ "x86_64-linux" ];
  }
  */


  /* KVM VMs hosted on stan. */

  { # 32-bit OpenIndiana 151a (in a VM).
    hostName = "tweek";
    ipAddress = "192.168.1.50";
    ethernetAddress = "00:16:3e:00:00:01";
    systems = [ "i686-solaris" ];
    maxJobs = 1;
    buildUser = "nix";
  }

  { # Legacy FreeBSD machine.
    hostName = "losser";
    ipAddress = "192.168.1.53";
    ethernetAddress = "00:16:3e:00:00:04";
    systems = [ "i686-freebsd" ];
  }

  { # Ubuntu 10.10 test machine.
    hostName = "meerkat";
    ipAddress = "192.168.1.54";
    ethernetAddress = "00:16:3e:00:00:05";
    systems = [ "i686-linux" ];
  }

  { # 64-bit FreeBSD build machine (in a VM).
    hostName = "beastie";
    ipAddress = "192.168.1.56";
    ethernetAddress = "00:16:3e:00:00:07";
    system = "x86_64-freebsd";
    maxJobs = 1;
    buildUser = "nix";
  }

  { # 32-bit FreeBSD build machine (in a VM).
    hostName = "demon";
    ipAddress = "192.168.1.57";
    ethernetAddress = "00:16:3e:00:00:08";
    system = "i686-freebsd";
    maxJobs = 1;
    buildUser = "nix";
  }

]
