lib: with lib;

[
  { # Web frontend.
    hostName = "cartman";
    ipAddress = "192.168.1.5";
    system = "i686-linux";
    aliases = ["main"];
    maxJobs = 2;
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

  {
    hostName = "phillip";
    ipAddress = "192.168.1.13";
    ethernetAddress = "00:19:d1:19:2a:31";
    system = "i686-freebsd";
    aliases = ["freebsd-1"];
    maxJobs = 2;
    buildUser = "buildfarm";
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

  { # New Hydra server.
    hostName = "lucifer";
    ipAddress = "192.168.1.25";
    ethernetAddress = "84:2B:2B:0B:98:F0";
  }


  # The following are Xen VMs hosted on mrhankey.
  # Note that 00:16:3e is the prefix for Xen MAC addresses.
  
  { # OpenSolaris 2009.06 (32 bit).
    hostName = "tweek";
    ipAddress = "192.168.1.50";
    ethernetAddress = "00:16:3e:00:00:01";
    systems = [ "i386-sunos" ];
    maxJobs = 2;
  }

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

  { # Another NixOS test machine.
    hostName = "clyde";
    ipAddress = "192.168.1.55";
    ethernetAddress = "00:16:3e:00:00:06";
    systems = [ "x86_64-linux" ];
  }

  { # 48 core powerrrr
    hostName = "wendy";
    ipAddress = "192.168.1.26";
    ethernetAddress = "f0:4d:a2:40:1b:be";
    systems = [ "x86_64-linux" ];
  }
  { # 48 core powerrrr
    hostName = "ike";
    ipAddress = "192.168.1.27";
    ethernetAddress = "f0:4d:a2:40:1b:91";
    systems = [ "x86_64-linux" ];
  }
  { # 48 core powerrrr
    hostName = "shelley";
    ipAddress = "192.168.1.28";
    ethernetAddress = "f0:4d:a2:40:10:6c";
    systems = [ "x86_64-linux" ];
  }
  
]

# Machines for the agilecloud experiment.
++ flip map (range 0 9) (nr:
  { hostName = "agilecloud0${toString nr}";
    ipAddress = "192.168.1.${toString (builtins.add nr 80)}";
    ethernetAddress = "00:16:3e:00:34:0${toString nr}";
    systems = [ "i686-linux" ];
  }
)
++ flip map (range 10 29) (nr:
  { hostName = "agilecloud${toString nr}";
    ipAddress = "192.168.1.${toString (builtins.add nr 80)}";
    ethernetAddress = "00:16:3e:00:34:${toString nr}";
    systems = [ "i686-linux" ];
  }
)
