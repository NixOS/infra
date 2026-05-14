{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    htop
    nix-top
  ];
}
