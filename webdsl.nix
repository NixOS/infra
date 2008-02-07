{
  boot = {
    grubDevice = "/dev/sda";
    
    initrd = {
      extraKernelModules = [ "mptbase" "mptscsih" "mptsas" ];
    };
  };

  fileSystems = [
    {
      mountPoint = "/";
      device = "/dev/sda4";
      fsType = "ext3";
    }
  ];

  swapDevices = [
    { device = "/dev/sda3"; }
  ];

  networking = {
    defaultGateway = "130.161.158.1";
    hostName = "webdsl";
    domain = "st.ewi.tudelft.nl";

    interfaces = [ { ipAddress = "130.161.159.185"; name = "eth0"; subnetMask = "255.255.254.0"; } ];
    nameservers = [ "130.161.158.4" "130.161.158.133" ];
    useDHCP = false;
  };

  services = {
    sshd = {
      enable = true;
    };

    httpd = {
      enable = true;
      adminAddr = "webdsl@st.ewi.tudelft.nl";
      mod_jk = {
        enable = true;
	applicationMappings = [ "webdslorg" ];
      };
    };
    
    mysql = {
      enable = true;
    };
    
    jboss = {
      enable = true;
      useJK = true;
    };
    
    vsftpd = {
      enable = true;
      anonymousUser = true;
    };
  };
}
