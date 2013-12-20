let
  region = "eu-west-1";
  zone = "eu-west-1a";
  accessKeyId = "lb-nixos";
in

{
  network.description = "Nixos.org Infrastructure";

  resources.ebsVolumes.tarballs =
    { name = "Nixpkgs source tarball mirror";
      inherit region zone accessKeyId;
      size = 100;
    };

  resources.ebsVolumes.releases =
    { name = "Nix/Nixpkgs/NixOS releases";
      inherit region zone accessKeyId;
      size = 500;
    };

  resources.ebsVolumes.data =
    { name = "Misc. data";
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
      deployment.ec2.region = region;
      deployment.ec2.zone = zone;
      deployment.ec2.instanceType = "m1.medium";
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
          device = "/dev/xvdi";
          ec2.disk = resources.ebsVolumes.releases;
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

      imports = [ ./webserver.nix ];
    };
}
