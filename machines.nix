[
  {
    hostName = "cartman";
    ipAddress = "192.168.1.5";
    system = "i686-linux";
    aliases = ["main"];
    maxJobs = 2;
  }
  
  {
    hostName = "kenny";
    ipAddress = "192.168.1.19";
    ethernetAddress = "00:22:19:55:cc:0d";
    systems = [ "x86_64-linux" "i686-linux" ];
    maxJobs = 8;
    speedFactor = 2;
    buildUser = "buildfarm";
  }
  
  {
    hostName = "stan";
    ipAddress = "192.168.1.20";
    ethernetAddress = "00:22:19:55:bf:2e";
    systems = [ "x86_64-linux" "i686-linux" ];
    maxJobs = 8;
    speedFactor = 2;
    buildUser = "buildfarm";
  }
  
  {
    hostName = "kyle";
    ipAddress = "192.168.1.21";
    ethernetAddress = "00:22:19:55:c1:18";
    systems = [ "x86_64-linux" "i686-linux" ];
    maxJobs = 8;
    speedFactor = 2;
    buildUser = "buildfarm";
  }
  
  {
    hostName = "garrison";
    ipAddress = "192.168.1.11";
    ethernetAddress = "00:19:d1:10:37:54";
    system = "i686-cygwin";
    aliases = ["winxp32-1" "winxp32" "winxp"];
    maxJobs = 2;
    buildUser = "nix";
  }

  {
    hostName = "terrance";
    ipAddress = "192.168.1.12";
    ethernetAddress = "00:19:d1:10:37:49";
    system = "i686-openbsd";
    aliases = ["openbsd-1"];
    maxJobs = 2;
    buildUser = "buildfarm";
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
  
  {
    hostName = "jimmy";
    ipAddress = "192.168.1.14";
    ethernetAddress = "00:16:76:9a:32:1d";
    system = "i686-linux";
    aliases = ["linux32-1" "linux32" "linux"];
    maxJobs = 2;
    #buildUser = "buildfarm";
  }
  
  {
    hostName = "timmy";
    ipAddress = "192.168.1.15";
    ethernetAddress = "00:19:d1:1d:c4:9a";
    system = "i686-linux";
    aliases = ["linux32-2"];
    maxJobs = 2;
    #buildUser = "buildfarm";
  }
  
  {
    hostName = "token";
    ipAddress = "192.168.1.16";
    ethernetAddress = "00:16:cb:a6:13:28";
    system = "i686-darwin";
    aliases = ["mac86-1" "mac"];
    maxJobs = 2;
    buildUser = "nix";
  }
  
  {
    hostName = "black";
    ipAddress = "192.168.1.17";
    ethernetAddress = "00:16:cb:a6:13:d7";
    system = "i686-darwin";
    aliases = ["mac86-2"];
    maxJobs = 2;
    buildUser = "nix";
  }

  {
    hostName = "butters";
    ipAddress = "192.168.1.23";
    ethernetAddress = "00:24:36:f3:cd:c0";
    system = "x86_64-darwin";
    aliases = ["mac64-1"];
    maxJobs = 2;
    buildUser = "nix";
  }
  
  {
    hostName = "hydra";
    ipAddress = "192.168.1.18";
    ethernetAddress = "00:22:19:55:bf:24";
  }

  {
    hostName = "chef";
    ipAddress = "192.168.1.22";
    ethernetAddress = "00:26:b9:35:bb:ca";
  }

  {
    hostName = "mrhankey";
    ipAddress = "192.168.1.24";
    ethernetAddress = "00:1D:09:0E:09:E5";
  }

  {
    hostName = "lucifer";
    ipAddress = "192.168.1.25";
    ethernetAddress = "84:2B:2B:0B:98:F0";
  }


  # The following are Xen VMs hosted on mrhankey.
  # Note that 00:16:3e is the prefix for Xen MAC addresses.
  
  {
    hostName = "tweek";
    ipAddress = "192.168.1.50";
    ethernetAddress = "00:16:3e:00:00:01";
    systems = [ "i386-sunos" ];
    maxJobs = 2;
  }

  {
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
    
  { # Ubuntu 10.10 machine.
    hostName = "meerkat";
    ipAddress = "192.168.1.54";
    ethernetAddress = "00:16:3e:00:00:05";
    systems = [ "i686-linux" ];
  }
    
]
