let
  region = "eu-west-1";
  zone = "eu-west-1a";
  accessKeyId = ""; # FIXME
  sshKeys = import ../ssh-keys.nix;
in

{
  resources.ec2KeyPairs.default =
    { inherit region accessKeyId;
    };

  resources.vpc.bastion-vpc =
    {
      inherit region accessKeyId;
      instanceTenancy = "default";
      enableDnsSupport = true;
      enableDnsHostnames = true;
      cidrBlock = "10.0.0.0/16";
    };

  resources.vpcSubnets.bastion-subnet =
    { resources, lib, ... }:
    {
      inherit region zone accessKeyId;
      vpcId = resources.vpc.bastion-vpc;
      cidrBlock = "10.0.0.0/19";
      mapPublicIpOnLaunch = true;
    };

  resources.ec2SecurityGroups.bastion-sg =
    { resources, lib, ... }:
    {
      inherit region accessKeyId;
      vpcId = resources.vpc.bastion-vpc;
      rules =
        with import ../ip-addresses.nix;
        map
          (ip: { toPort = 22; fromPort = 22; sourceIp = "${ip}/32"; })
          [ eelcoHome
            eelcoEC2
            rob1
            rob2
            graham
            zimbatm
            amine
            "34.254.208.229" # == resources.elasticIPs."bastion.nixos.org".address FIXME: doesn't work
          ];
    };

  resources.vpcRouteTables.bastion-route-table =
    { resources, ... }:
    {
      inherit region accessKeyId;
      vpcId = resources.vpc.bastion-vpc;
    };

  resources.vpcRouteTableAssociations.bastion-assoc =
    { resources, ... }:
    {
      inherit region accessKeyId;
      subnetId = resources.vpcSubnets.bastion-subnet;
      routeTableId = resources.vpcRouteTables.bastion-route-table;
    };

  resources.vpcInternetGateways.bastion-igw =
    { resources, ... }:
    {
      inherit region accessKeyId;
      vpcId = resources.vpc.bastion-vpc;
    };

  resources.vpcRoutes.bastion-route =
    { resources, ... }:
    {
      inherit region accessKeyId;
      routeTableId = resources.vpcRouteTables.bastion-route-table;
      destinationCidrBlock = "0.0.0.0/0";
      gatewayId = resources.vpcInternetGateways.bastion-igw;
    };

  resources.elasticIPs."bastion.nixos.org" =
    { inherit region accessKeyId;
      vpc = true;
    };

  bastion =
    { config, pkgs, resources, ... }:

    { deployment.targetEnv = "ec2";
      deployment.ec2.tags.Name = "NixOS.org Infrastructure Deployment Server";
      deployment.owners = [ "edolstra@gmail.com" "rob.vermaas@gmail.com" ];
      deployment.ec2.region = region;
      deployment.ec2.zone = zone;
      deployment.ec2.instanceType = "t2.medium";
      deployment.ec2.accessKeyId = accessKeyId;
      deployment.ec2.keyPair = resources.ec2KeyPairs.default;
      deployment.ec2.securityGroups = [];
      deployment.ec2.securityGroupIds = [ resources.ec2SecurityGroups.bastion-sg.name ];
      deployment.ec2.subnetId = resources.vpcSubnets.bastion-subnet;
      deployment.ec2.associatePublicIpAddress = true;
      deployment.ec2.ebsInitialRootDiskSize = 40;
      deployment.ec2.elasticIPv4 = resources.elasticIPs."bastion.nixos.org";

      imports =
        [ ../modules/common.nix
          ../modules/tarball-mirror.nix
        ];

      users.extraUsers.tarball-mirror.openssh.authorizedKeys.keys = [ sshKeys.eelco ];

      users.extraUsers.deploy =
        { description = "NixOps deployments";
          isNormalUser = true;
          openssh.authorizedKeys.keys =
            [ sshKeys.eelco sshKeys.rob sshKeys.graham sshKeys.zimbatm sshKeys.amine ];
        };

      environment.systemPackages =
        [ pkgs.nixops
          pkgs.awscli
          pkgs.tmux
          pkgs.terraform-full
        ];

      #nix.gc.automatic = true;
      nix.gc.dates = "daily";

      # Temporary hack until we have proper users/roles.
      services.openssh.extraConfig =
        ''
          AcceptEnv AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
        '';
    };
}
