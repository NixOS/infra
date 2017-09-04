{ type, tag, ... }:

let
  region = "us-east-1";
  accessKeyId = "hydra-provisioner";
in

{

  resources.ec2KeyPairs.default =
    { inherit region accessKeyId;
    };

  machine =
    { config, lib, pkgs, resources, ... }:
    {
      deployment.targetEnv = "ec2";
      deployment.ec2.accessKeyId = accessKeyId;
      deployment.ec2.region = region;
      deployment.ec2.instanceType = "m4.xlarge";
      deployment.ec2.spotInstancePrice = 10;
      deployment.ec2.spotInstanceTimeout = 5 * 60;
      deployment.ec2.keyPair = resources.ec2KeyPairs.default;
      deployment.ec2.subnetId = "subnet-1eb22868";
      deployment.ec2.associatePublicIpAddress = true;
      deployment.ec2.securityGroupIds = [ "sg-b2ee60ca" ];
      deployment.ec2.tags.Name = "Hydra Builder";
      deployment.ec2.ebsInitialRootDiskSize = 100;
      deployment.owners = [ "eelco.dolstra@logicblox.com" ];

      imports =
        [ <nixpkgs/nixos/modules/profiles/minimal.nix>
          <hydra-provisioner/auto-shutdown.nix>
	  #../delft/diffoscope.nix
        ];

      users.extraUsers.root.openssh.authorizedKeys.keys =
        [ ''command="nix-store --serve --write" ${(import ../ssh-keys.nix).hydra-queue-runner}''
        ];

      nix.package = pkgs.nixUnstable;

      nix.buildCores = 0;

      nix.useSandbox = true;

      nix.gc.automatic = true;
      nix.gc.dates = "*:0/30";
      nix.gc.options = ''--max-freed "$((15 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';

      # Use the cache.nixos.org S3 bucket directly, rather than going
      # through Cloudfront, since same-region EC2<->S3 traffic is
      # free. Also it avoids caching of negative lookups by
      # Cloudfront.
      nix.binaryCaches = lib.mkForce [ https://nix-cache.s3.amazonaws.com/ ];
    };

}
