let
  region = "eu-west-1";
  zone = "eu-west-1a"; # Do not change the zone, due to Reserved Instance.
  accessKeyId = "lb-nixos";
in

{
  network.description = "NixOS.org Infrastructure";

  resources.ebsVolumes.tarballs =
    { tags.Name = "Nixpkgs source tarball mirror";
      inherit region zone accessKeyId;
      size = 100;
    };

  resources.ebsVolumes.releases2 =
    { tags.Name = "Nix/Nixpkgs/NixOS releases";
      inherit region zone accessKeyId;
      size = 1024;
    };

  resources.ebsVolumes.data =
    { tags.Name = "Misc. NixOS.org data";
      inherit region zone accessKeyId;
      size = 10;
    };

  resources.elasticIPs."nixos.org" =
    { inherit region accessKeyId;
    };

  resources.ec2KeyPairs.default =
    { inherit region accessKeyId;
    };

  webserver =
    { config, pkgs, resources, ... }:

    { deployment.targetEnv = "ec2";
      deployment.ec2.tags.Name = "NixOS.org Webserver";
      deployment.owners = [ "eelco.dolstra@logicblox.com" "rob.vermaas@logicblox.com" ];
      deployment.ec2.region = region;
      deployment.ec2.zone = zone;
      deployment.ec2.instanceType = "m3.medium";
      deployment.ec2.accessKeyId = accessKeyId;
      deployment.ec2.keyPair = resources.ec2KeyPairs.default;
      deployment.ec2.securityGroups = [ "public-web" "public-ssh" ];
      deployment.ec2.elasticIPv4 = resources.elasticIPs."nixos.org";

      fileSystems."/tarballs" =
        { autoFormat = true;
          fsType = "ext4";
          device = "/dev/xvdf";
          ec2.disk = resources.ebsVolumes.tarballs;
        };

      fileSystems."/releases" =
        { autoFormat = true;
          fsType = "ext4";
          device = "/dev/xvdj";
          ec2.disk = resources.ebsVolumes.releases2;
        };

      fileSystems."/data" =
        { autoFormat = true;
          fsType = "ext4";
          device = "/dev/xvdh";
          ec2.disk = resources.ebsVolumes.data;
        };

      fileSystems."/data/releases" =
        { device = "/releases";
          fsType = "none";
          options = "bind";
        };

      system.stateVersion = "14.12";

      imports = [ ./webserver.nix ];
    };
}
