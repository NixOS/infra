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
    hostName = "hydra";
    ipAddress = "192.168.1.18";
    ethernetAddress = "00:22:19:55:bf:24";
  }
]
