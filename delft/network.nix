{
  hydra = { deployment.targetHost = "hydra.ewi.tudelft.nl"; imports = [ ./build-machines-dell-1950.nix ]; };
  lucifer = { deployment.targetHost = "lucifer.ewi.tudelft.nl"; imports = [ ./lucifer.nix ]; };
  wendy = { deployment.targetHost = "wendy.ewi.tudelft.nl"; imports = [ ./wendy.nix ]; };
  ike = { deployment.targetHost = "ike.ewi.tudelft.nl"; imports = [ ./build-machines-dell-r815.nix ]; };
  packet-epyc-1 = { deployment.targetHost = "147.75.198.47"; imports = [ ./packet/packet-epyc-1.nix ./build-machines-common.nix ]; };
  chef = import ./chef.nix;
  eris = import ./eris.nix;
}
