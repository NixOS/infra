{
  lib,
  ...
}:

{
  services.openssh = {
    enable = true;
    authorizedKeysFiles = lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ];
  };
}
