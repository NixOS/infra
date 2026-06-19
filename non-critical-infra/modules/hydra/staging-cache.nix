{
  # Substituter the staging queue runner forces builders onto for presigned
  # uploads (services.hydra-queue-runner-dev.settings.forcedSubstituters).
  nix.settings = {
    extra-substituters = [ "https://cache-staging.nixos.org" ];
    extra-trusted-public-keys = [
      "staging-hydra.nixos.org:XTeS2S4YgmVOVVTBazog3M6pSHoUKw0k5mCcqdmPeCU="
    ];
  };
}
