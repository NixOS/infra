let
  region = "eu-west-1";
  zone = "eu-west-1a";
  accessKeyId = ""; # FIXME
in

{
  network.description = "NixOS.org Infrastructure";

  resources.ebsVolumes.releases =
    { tags.Name = "Nix/Nixpkgs/NixOS releases";
      inherit region zone accessKeyId;
      size = 1024;
    };

  resources.ebsVolumes.data-new =
    { tags.Name = "Misc. NixOS.org data";
      inherit region zone accessKeyId;
      size = 30;
    };

  resources.elasticIPs."nixos.org" =
    { inherit region accessKeyId;
      vpc = true;
    };

  resources.ec2KeyPairs.default =
    { inherit region accessKeyId;
    };

  resources.vpc.nixos-org-vpc =
    {
      inherit region accessKeyId;
      instanceTenancy = "default";
      enableDnsSupport = true;
      enableDnsHostnames = true;
      cidrBlock = "10.0.0.0/16";
    };

  resources.vpcSubnets.nixos-org-subnet =
    { resources, lib, ... }:
    {
      inherit region zone accessKeyId;
      vpcId = resources.vpc.nixos-org-vpc;
      cidrBlock = "10.0.0.0/19";
      mapPublicIpOnLaunch = true;
    };

  resources.ec2SecurityGroups.nixos-org-sg =
    { resources, lib, ... }:
    {
      inherit region accessKeyId;
      vpcId = resources.vpc.nixos-org-vpc;
      rules =
        with import ../ip-addresses.nix;
	[ { toPort =  80; fromPort =  80; sourceIp = "0.0.0.0/0"; }
          { toPort = 443; fromPort = 443; sourceIp = "0.0.0.0/0"; }
	]
        ++ map
          (ip: { toPort = 22; fromPort = 22; sourceIp = "${ip}/32"; })
          [ eelcoHome
            eelcoEC2
            "34.254.208.229" # == "bastion.nixos.org"
          ];
    };

  resources.vpcRouteTables.nixos-org-route-table =
    { resources, ... }:
    {
      inherit region accessKeyId;
      vpcId = resources.vpc.nixos-org-vpc;
    };

  resources.vpcRouteTableAssociations.nixos-org-assoc =
    { resources, ... }:
    {
      inherit region accessKeyId;
      subnetId = resources.vpcSubnets.nixos-org-subnet;
      routeTableId = resources.vpcRouteTables.nixos-org-route-table;
    };

  resources.vpcInternetGateways.nixos-org-igw =
    { resources, ... }:
    {
      inherit region accessKeyId;
      vpcId = resources.vpc.nixos-org-vpc;
    };

  resources.vpcRoutes.nixos-org-route =
    { resources, ... }:
    {
      inherit region accessKeyId;
      routeTableId = resources.vpcRouteTables.nixos-org-route-table;
      destinationCidrBlock = "0.0.0.0/0";
      gatewayId = resources.vpcInternetGateways.nixos-org-igw;
    };

  webserver =
    { config, pkgs, resources, ... }:

    { deployment.targetEnv = "ec2";
      deployment.ec2.tags.Name = "NixOS.org Webserver";
      deployment.owners = [ "eelco.dolstra@logicblox.com" "rob.vermaas@logicblox.com" ];
      deployment.ec2.region = region;
      deployment.ec2.zone = zone;
      deployment.ec2.instanceType = "t2.large";
      deployment.ec2.accessKeyId = accessKeyId;
      deployment.ec2.keyPair = resources.ec2KeyPairs.default;
      deployment.ec2.securityGroups = [];
      deployment.ec2.securityGroupIds = [ resources.ec2SecurityGroups.nixos-org-sg.name ];
      deployment.ec2.subnetId = resources.vpcSubnets.nixos-org-subnet;
      deployment.ec2.associatePublicIpAddress = true;
      deployment.ec2.elasticIPv4 = resources.elasticIPs."nixos.org";
      deployment.ec2.ebsInitialRootDiskSize = 30;

      fileSystems."/releases" =
        { autoFormat = true;
          fsType = "ext4";
          device = "/dev/xvdj";
          ec2.disk = resources.ebsVolumes.releases;
        };

      fileSystems."/data" =
        { autoFormat = true;
          fsType = "ext4";
          device = "/dev/xvdh";
          ec2.disk = resources.ebsVolumes.data-new;
        };

      fileSystems."/data/releases" =
        { device = "/releases";
          fsType = "none";
          options = [ "bind" ];
        };

      fileSystems."/home" =
        { device = "/data/home";
          fsType = "none";
          options = [ "bind" ];
        };

      system.stateVersion = "17.09";

      imports =
        [ ./webserver.nix
          ../modules/hydra-mirror-user.nix
          ../modules/prometheus
	];

      users.users.hydra-mirror.openssh.authorizedKeys.keys =
        [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA/r65Jgp3pe+wNh9Vp64jdTxD9G6Gn5F3sidnydinBK hydra-mirror@bastion" ];
    };

}
