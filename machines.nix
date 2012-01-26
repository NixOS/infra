lib: with lib;

[ /* Physical machines. */

  { # Web frontend.
    hostName = "cartman";
    ipAddress = "192.168.1.5";
    system = "i686-linux";
    aliases = ["main"];
    maxJobs = 2;
  }
  
  { # APC UPS.
    hostName = "ups";
    ipAddress = "192.168.1.6";
    ethernetAddress = "00:c0:b7:5b:16:56";
  }

  { # 8-core NixOS build machine.
    hostName = "kenny";
    ipAddress = "192.168.1.19";
    ethernetAddress = "00:22:19:55:cc:0d";
    systems = [ "x86_64-linux" "i686-linux" ];
    maxJobs = 8;
    speedFactor = 2;
    buildUser = "buildfarm";
  }
  
  { # 8-core NixOS build machine.
    hostName = "stan";
    ipAddress = "192.168.1.20";
    ethernetAddress = "00:22:19:55:bf:2e";
    systems = [ "x86_64-linux" "i686-linux" ];
    maxJobs = 8;
    speedFactor = 2;
    buildUser = "buildfarm";
  }
  
  { # 8-core NixOS build machine.
    hostName = "kyle";
    ipAddress = "192.168.1.21";
    ethernetAddress = "00:22:19:55:c1:18";
    systems = [ "x86_64-linux" "i686-linux" ];
    maxJobs = 8;
    speedFactor = 2;
    buildUser = "buildfarm";
  }
  
  { # Windows XP build machine.
    hostName = "garrison";
    ipAddress = "192.168.1.11";
    ethernetAddress = "00:19:d1:10:37:54";
    system = "i686-cygwin";
    aliases = ["winxp32-1" "winxp32" "winxp"];
    maxJobs = 2;
    buildUser = "nix";
  }

  { # 64-bit Mac OS X build machine.
    hostName = "butters";
    ipAddress = "192.168.1.23";
    ethernetAddress = "00:24:36:f3:cd:c0";
    system = "x86_64-darwin";
    aliases = ["mac64-1"];
    maxJobs = 2;
    buildUser = "nix";
  }
  
  { # Old Hydra server.
    hostName = "hydra";
    ipAddress = "192.168.1.18";
    ethernetAddress = "00:22:19:55:bf:24";
  }

  { # Xen machine.
    hostName = "mrhankey";
    ipAddress = "192.168.1.24";
    ethernetAddress = "00:1D:09:0E:09:E5";
  }

  { # Hydra server.
    hostName = "lucifer";
    ipAddress = "192.168.1.25";
    ethernetAddress = "84:2B:2B:0B:98:F0";
  }

  { # 48-core NixOS machine for random hackery.
    hostName = "wendy";
    ipAddress = "192.168.1.26";
    ethernetAddress = "f0:4d:a2:40:1b:be";
    systems = [ "x86_64-linux" ];
  }
  
  { # 48-core NixOS build machine.
    hostName = "ike";
    ipAddress = "192.168.1.27";
    ethernetAddress = "f0:4d:a2:40:1b:91";
    systems = [ "x86_64-linux" ];
  }
  
  { # 48-core NixOS build machine.
    hostName = "shelley";
    ipAddress = "192.168.1.28";
    ethernetAddress = "f0:4d:a2:40:10:6c";
    systems = [ "x86_64-linux" ];
  }


  /* Xen VMs hosted on mrhankey.  Note that 00:16:3e is the prefix for
     Xen MAC addresses. */
  
  { # NixOS test machine.
    hostName = "drdoctor";
    ipAddress = "192.168.1.51";
    ethernetAddress = "00:16:3e:00:00:02";
    systems = [ "x86_64-linux" ];
  }
    
  { # Legacy JIRA server, put in its own Xen ghetto because our JIRA
    # is very old and probably insecure.
    hostName = "mrkitty";
    ipAddress = "192.168.1.52";
    ethernetAddress = "00:16:3e:00:00:03";
    systems = [ "x86_64-linux" ];
  }

  { # Another NixOS test machine.
    hostName = "clyde";
    ipAddress = "192.168.1.55";
    ethernetAddress = "00:16:3e:00:00:06";
    systems = [ "x86_64-linux" ];
  }

  
  /* KVM VMs hosted on stan. */
  
  { # 32-bit OpenIndiana 151a (in a VM).
    hostName = "tweek";
    ipAddress = "192.168.1.50";
    ethernetAddress = "00:16:3e:00:00:01";
    systems = [ "i686-solaris" ];
    maxJobs = 1;
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
    buildUser = "buildfarm";
  }
  
  { # 32-bit FreeBSD build machine (in a VM).
    hostName = "demon";
    ipAddress = "192.168.1.57";
    ethernetAddress = "00:16:3e:00:00:08";
    system = "i686-freebsd";
    maxJobs = 1;
    buildUser = "buildfarm";
  }
  
]
