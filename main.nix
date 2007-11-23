let 

  pkgs = import /etc/nixos/nixpkgs {};

  machines = import ./machines.nix;

  machineList = map (name: {hostName = name;} // builtins.getAttr name machines)
    (builtins.attrNames machines);

  # Produce the list of Nix build machines in the format expected by
  # the Nix daemon Upstart job.
  buildMachines =
    let addKey = machine: machine // 
      { sshKey = "/root/.ssh/id_buildfarm";
        sshUser = machine.buildUser;
      };
    in map addKey (pkgs.lib.filter (machine: machine ? buildUser) machineList);

in

rec {
  boot = {
    grubDevice = "/dev/sda";
    initrd = {
      extraKernelModules = ["arcmsr"];
    };
    kernelModules = ["kvm-intel"];
  };

  fileSystems = [
    { mountPoint = "/";
      label = "nixos";
    }
  ];

  swapDevices = [
    { label = "swap1"; }
  ];
  
  nix = {
    maxJobs = 2;
    distributedBuilds = true;
    inherit buildMachines;
  };
  
  networking = {
    hostName = "cartman";
    domain = "buildfarm";

    interfaces = [
      { name = "eth1";
        ipAddress = "130.161.158.181";
        subnetMask = "255.255.254.0";
      }
      { name = "eth0";
        ipAddress = machines.cartman.ipAddress;
      }
    ];

    defaultGateway = "130.161.158.1";

    nameservers = ["130.161.158.4" "130.161.33.17" "130.161.180.1"];

    extraHosts = 
      let toHosts = m: "${m.ipAddress} ${m.hostName} ${pkgs.lib.concatStringsSep " " m.aliases}\n"; in
      pkgs.lib.concatStrings (map toHosts machineList);

    localCommands =
      # Provide NATting for the build machines on 192.168.1.*.
      # Obviously, this should be something that NixOS provides.
      "
        export PATH=${pkgs.iptables}/sbin:$PATH

        modprobe ip_tables
        modprobe ip_conntrack_ftp
        modprobe ip_nat_ftp
        modprobe ipt_LOG
        modprobe ip_nat
        modprobe xt_tcpudp

        iptables -t nat -F
        iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -d 192.168.1.0/24 -j ACCEPT
        iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j SNAT --to-source 130.161.158.181

        echo 1 > /proc/sys/net/ipv4/ip_forward
      ";

    defaultMailServer = {
      directDelivery = true;
      hostName = "smtp.st.ewi.tudelft.nl";
      domain = "st.ewi.tudelft.nl";
    };
  };

  services = {
    sshd = {
      enable = true;
    };

    dhcpd = {
      enable = true;
      configFile = ./dhcpd.conf;
      interfaces = ["eth0"];
    };
    
    nagios = {
      enable = true;
      enableWebInterface = true;
      objectDefs = [
        ./nagios-base.cfg
        (pkgs.writeText "nagios-machines.cfg" (
          map (machine:
            let hostName = machine.hostName; in
            "
              define host {
                host_name  ${hostName}
                use        generic-server
                alias      Build machine ${hostName} (${machine.system})
                address    ${hostName}
                hostgroups tud-buildfarm
              }

              define service {
                service_description SSH on ${hostName}
                use                 local-service
                host_name           ${hostName}
                servicegroups       ssh
                check_command       check_ssh
              }

              #define service {
              #  service_description /nix on ${hostName}
              #  use                 local-service
              #  host_name           ${hostName}
              #  servicegroups       diskspace
              #  check_command       check_remote_disk!nagios!/var/lib/nagios/id_nagios!75%!10%!/nix
              #}
            "
          ) machineList
        ))
      ];
    };
    
    httpd = {
      enable = true;
      adminAddr = "eelco@cs.uu.nl";
      hostName = "buildfarm.st.ewi.tudelft.nl";

      subservices = {
        subversion = {
          enable = true;
          dataDir = "/data/subversion";
          notificationSender = "svn@example.org";
          userCreationDomain = "st.ewi.tudelft.nl";
          
          organization = {
            name = "Software Engineering Research Group, TU Delft";
            url  = "http://swerl.tudelft.nl";
            logo = ./serg-logo.png;
          };
        };
      };

      extraSubservices = {
        enable = true;
        services = [distManagerService rootFiles];
      };
    };
  };

  distManagerService = webServer : pkgs :
    (distManager webServer pkgs) {
      distDir = "/data/webserver/dist";
      distPrefix = "/releases";
      distConfDir = "/data/webserver/dist-conf";
      directories = ./dist-manager/directories.conf;
    };

  distManager = webServer : pkgs : {distDir, distPrefix, distConfDir, directories} :
    import ../../services/dist-manager {
      inherit (pkgs) stdenv perl;
      saxon8 = pkgs.saxonb;
      inherit distDir distPrefix distConfDir directories;
      canonicalName = "http://" + webServer.hostName + 
        (if webServer.httpPort == 80 then "" else ":" + (toString webServer.httpPort));
    };

  rootFiles =  webServer : pkgs :
    import ../../services/apache-httpd/subservices/serve-files {
      directory = ./webroot;
      urlPath = "/";
      inherit (pkgs) stdenv;
    };
}
