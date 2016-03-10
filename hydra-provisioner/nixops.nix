{ type, tag, ... }:

let
  region = "us-east-1";
  accessKeyId = "lb-nixos";
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
      deployment.ec2.keyPair = resources.ec2KeyPairs.default;
      deployment.ec2.subnetId = "subnet-0723eb5e";
      deployment.ec2.associatePublicIpAddress = true;
      deployment.ec2.securityGroupIds = [ "sg-67a05003" ];
      deployment.ec2.tags.Name = "Hydra Builder";
      deployment.ec2.ebsInitialRootDiskSize = 100;
      deployment.owners = [ "eelco.dolstra@logicblox.com" ];

      imports =
        [ <nixpkgs/nixos/modules/profiles/minimal.nix>
          <hydra-provisioner/auto-shutdown.nix>
        ];

      users.extraUsers.root.openssh.authorizedKeys.keys =
        [ # ''command="nix-store --serve --write" ${builtins.readFile ~/.ssh/id_dsa.pub} # for testing
          ''command="nix-store --serve --write" ssh-dss AAAAB3NzaC1kc3MAAACBAMHRjGSDaBp4Z30JF4S9ApabBCpdr57Ad0aD9oH2A/WEFnWYQSAzK4E/HHD2DV2XP1stNkZ1ks2v3F4Yu/veR+qVlUWbJW1RIIfuQgkG44K0R3C2qx4BAZUVYzju1NVCJbBOO6ipVY9cfmpokV52HZFhP/2HocTNLoav3F0AsbbJAAAAFQDaJiQdpJBEa4Wr5FfVl1kYqmQZJwAAAIEAwbern5XL+SNIMa+sJ3CBhrWyYExYWiUbdmhQEfyEAUmoPsEr1qpb+0WREic9Nrxz48QWZDK5xMvzZyQEkuAMJUBWcdm12rME7WMvg7OZGr9DADjAtfMfj3Ui2XvOuQ3ia/OTsMGkQTDWnkOM9Ni128SNSl9urFBlXATdGvo+468AAACBAK8s6LddhhkRqsF/l/L2ooS8c8A1rTFWAOy3/sgXFNvMyS/Mig2p966xRrRHr7Bc+H2SuKEE5WmLCXqymgxLHhrFU4zm/W/ej1yB1CAThd4xUfgJu4touJROjvcD1zzlmLeat0fp2k5mCuiLKcTKi0vxKWiiopF9nvBBK+7ODPC7 buildfarm@nixos''
        ];

      nix.package = pkgs.nixUnstable;

      nix.buildCores = 0;

      nix.gc.automatic = true;
      nix.gc.dates = "*:0/30";
      nix.gc.options = ''--max-freed "$((15 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';
    };

}
