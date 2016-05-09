let
  region = "eu-west-1";
  zone = "eu-west-1a"; # Do not change the zone, due to Reserved Instance.
  accessKeyId = "lb-nixos";
in

{
  network.description = "NixOS.org Infrastructure";

  resources.ebsVolumes.releases =
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

  resources.s3Buckets.nixpkgs-tarballs =
    { config, ... }:
    { inherit region accessKeyId;
      name = "nixpkgs-tarballs";
      # All files are readable but not listable.
      # The s3-upload-tarballs user can upload files.
      policy =
        ''
          {
            "Version": "2008-10-17",
            "Statement": [
              {
                "Sid": "AllowPublicRead",
                "Effect": "Allow",
                "Principal": {"AWS": "*"},
                "Action": ["s3:GetObject"],
                "Resource": ["${config.arn}/*"]
              },
              {
                "Sid": "AllowUpload",
                "Effect": "Allow",
                "Principal": {"AWS": "arn:aws:iam::080433136561:user/s3-upload-tarballs"},
                "Action": ["s3:PutObject", "s3:PutObjectAcl"],
                "Resource": ["${config.arn}/*"]
              },
              {
                "Sid": "AllowUpload2",
                "Effect": "Allow",
                "Principal": {"AWS": "arn:aws:iam::080433136561:user/s3-upload-tarballs"},
                "Action": ["s3:ListBucket"],
                "Resource": ["${config.arn}"]
              }
            ]
          }
        '';
    };

  resources.s3Buckets.nix-cache =
    { config, ... }:
    { inherit accessKeyId;
      region = "us-east-1";
      name = "nix-cache";
      policy =
        ''
          {
            "Version": "2008-10-17",
            "Statement": [
              {
                "Sid": "AllowPublicRead",
                "Effect": "Allow",
                "Principal": {"AWS": "*"},
                "Action": ["s3:GetObject"],
                "Resource": ["${config.arn}/*"]
              }
            ]
          }
        '';
    };

  resources.s3Buckets.nix-test-cache =
    { config, ... }:
    { inherit region accessKeyId;
      name = "nix-test-cache";
      policy =
        ''
          {
            "Version": "2008-10-17",
            "Statement": [
              {
                "Sid": "AllowPublicRead",
                "Effect": "Allow",
                "Principal": {"AWS": "*"},
                "Action": ["s3:GetObject"],
                "Resource": ["${config.arn}/*"]
              },
              {
                "Sid": "AllowPublicList",
                "Effect": "Allow",
                "Principal": {"AWS": "*"},
                "Action": ["s3:ListBucket"],
                "Resource": ["${config.arn}"]
              }
            ]
          }
        '';
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
          ec2.disk = resources.ebsVolumes.data;
        };

      fileSystems."/data/releases" =
        { device = "/releases";
          fsType = "none";
          options = [ "bind" ];
        };

      swapDevices = [ { device = "/tmp/swapfile"; size = 1024; } ];

      system.stateVersion = "14.12";

      imports = [ ./webserver.nix ./hydra-mirror.nix ./tarball-mirror.nix ];
    };
}
