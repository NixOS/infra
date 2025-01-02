{
  networking = {
    domain = "builders.nixos.org";

    firewall = {
      # too spammy, rotates dmesg too quickly
      logRefusedConnections = false;
    };

    # we use networkd instead
    useDHCP = false;
  };
}
