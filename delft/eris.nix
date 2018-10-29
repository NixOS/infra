{ config, lib, pkgs, ... }:
{ deployment.targetEnv = "hetzner";
  deployment.hetzner.mainIPv4 = "138.201.32.77";
}
