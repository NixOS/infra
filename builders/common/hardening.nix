{
  # no priviledge escalation through sudo or polkit
  security.sudo.execWheelOnly = true;
  security.polkit.enable = false;

  # no password authentication
  services.openssh.settings = {
    KbdInteractiveAuthentication = false;
    PasswordAuthentication = false;
  };
}
