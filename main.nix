{
  boot = {
    grubDevice = "/dev/sda";
    initrd = {
      extraKernelModules = ["arcmsr"];
    };
    extraKernelModules = ["kvm-intel"];
  };

  fileSystems = [
    { mountPoint = "/";
      label = "nixos";
    }
  ];

  swapDevices = [
    { label = "swap1"; }
  ];
  
  networking = {
    interfaces = [
      { name = "eth0:0";
        ipAddress = "192.168.1.5";
      }
    ];
  };
  
  services = {
    sshd = {
      enable = true;
    };
    
    httpd = {
      enable = true;
      adminAddr = "admin@example.org";
      hostName = "dutiel.st.ewi.tudelft.nl";

      subservices = {

        subversion = {
          enable = true;
          dataDir = "/data/subversion";
          notificationSender = "svn@example.org";
          userCreationDomain = "st.ewi.tudelft.nl";
        };

      };

      extraSubservices = [
        
      ];
    
    };

  };

}
