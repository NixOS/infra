{
  boot = {
    grubDevice = "/dev/sda";
    initrd = {
      extraKernelModules = ["arcmsr"];
    };
  };

  fileSystems = [
    { mountPoint = "/";
      label = "nixos";
    }
  ];

  swapDevices = [
    { label = "swap1"; }
  ];
  
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
      
    };

  };

}
