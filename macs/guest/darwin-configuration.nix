{ config, lib, pkgs, ... }:

with lib;

let
  sshKeys = rec {
  eelco = "ssh-dss AAAAB3NzaC1kc3MAAACBAOo3foMFsYvc+LEVVTAeXpaxdOFG6O2NE9coxZYN6UtwE477GwkvZ4uKymAekq3TB8I6dDg4QFfE27fIip/rQHJ/Rus+KsxwnTbwPzE0WcZVpkKQsepsoqLkfwMpiPfn5/oxcnJsimwRY/E95aJmmOHdGaYWrc0t4ARa+6teUgdFAAAAFQCSQq2Wil0/X4hDypGGUKlKvYyaWQAAAIAy/0fSDnz1tZOQBGq7q78y406HfWghErrVlrW9g+foJQG5pgXXcdJs9JCIrlaKivUKITDsYnQaCjrZaK8eHnc4ksbkSLfDOxFnR5814ulCftrgEDOv9K1UU3pYketjFMvQCA2U48lR6jG/99CPNXPH55QEFs8H97cIsdLQw9wM4gAAAIEAmzWZlXLzIf3eiHQggXqvw3+C19QvxQITcYHYVTx/XYqZi1VZ/fkY8bNmdcJsWFyOHgEhpEca+xM/SNvH/14rXDmt0wtclLEx/4GVLi59hQCnnKqv7HzJg8RF4v6XTiROBAEEdb4TaFuFn+JCvqPzilTzXTexvZKJECOvfYcY+10= eelco.dolstra@logicblox.com";

  rob = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHp3/OZP2nRS5bM9E1xN8Q2L398kC+m4guORjKsmGjwnnHvYnTml5puE2ogl8Wdenbk7hf82+vKyB+Tktrhx+IBSym4lY+czR6W+39hlPYdLbi980yxYT9KEMSyMWJEgPVJ1BZvHqsHQiad/L3eoPmAIMDmcn4mLh9rya5/oMW/ZgsA6j28ClvWkDRyaTmTLOa0Im4nLoSbdo8kJqU+JX/YcXlMKUvFfdMcj4T9YYwV98LPWHnEHFmjtBBUXRUAIESMXS6pm3Pep3czkKUL4UF0u9f17b40OWlLOF4IQWE2jM9yK09DiIQUzeU2XKRNW116DnmDL5QIRNrYnhkYeeQI3U6WnVTPdTU9kBVTDjhM+6U6/LClGJaWiglwwrzHtVELHgMi280qRefQEftb4CI/IbcPNAxetJevV68I5NAjfdnmMx8YbhfIiEqAJtBi4TvoH7HjDH+72+ZFjQ10fpz/p+DgUtiNlRKz8tXSZ+mbLuhmOJOxtGQTH3viYbSpG/4F9uKW1ekX0RMyRxVvpjMxHtCL4daJI4RTHFXy4R16OKAlYe7gs9sqv7O0IujLJPex/rnN2U4syGaSH5q3UnGxci6qgn8yLEhSP+Gj0xdv5H3fVjr/kNNZGWDOz6nDUaJT+eWlmWU7hOvm0ricrz9GEPUTQ0Rh70sWTQFq3poWQ== cardno:000606167509";

  provisioner = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKDSfHu0xHu2qtWjmCC92rTMZfwZNKXrsJvPCLSoWtzR eelco.dolstra@deploy";

  danny = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDlxgNIC4HbyLXB7jexKOEDkMRmiIfDnjOrx445otnR7w87hAehq8If+lnfK/ezGbss6yuWpTjjlc9gi03AxxL9KJW+xAe8avoC36/EeFfBJtRFMaUTjZ0XrcW09Yl8b9BWKypOXSOoF5JAJjV3yI160p+bzhSa584gY+Gj6A2SkVpnUPQfahm3gj0esqVBYVHfN1KXsHq8S89RxOr9HrRU5mTyZn0xO6YE3w+PG2f77vBhZMutt2+28xcMZCNO0HyY/WkWZo7tmJB/HLEENzz1OYiYCXjSEAgEgMbx69kG8r2fOLkrpbKLc/Wbg6fMsi7DM2G5egFPAEqxF1HXHf9T dan@dans-mbp.ws.tudelft.net";

  build-farm = "ssh-dss AAAAB3NzaC1kc3MAAACBAMHRjGSDaBp4Z30JF4S9ApabBCpdr57Ad0aD9oH2A/WEFnWYQSAzK4E/HHD2DV2XP1stNkZ1ks2v3F4Yu/veR+qVlUWbJW1RIIfuQgkG44K0R3C2qx4BAZUVYzju1NVCJbBOO6ipVY9cfmpokV52HZFhP/2HocTNLoav3F0AsbbJAAAAFQDaJiQdpJBEa4Wr5FfVl1kYqmQZJwAAAIEAwbern5XL+SNIMa+sJ3CBhrWyYExYWiUbdmhQEfyEAUmoPsEr1qpb+0WREic9Nrxz48QWZDK5xMvzZyQEkuAMJUBWcdm12rME7WMvg7OZGr9DADjAtfMfj3Ui2XvOuQ3ia/OTsMGkQTDWnkOM9Ni128SNSl9urFBlXATdGvo+468AAACBAK8s6LddhhkRqsF/l/L2ooS8c8A1rTFWAOy3/sgXFNvMyS/Mig2p966xRrRHr7Bc+H2SuKEE5WmLCXqymgxLHhrFU4zm/W/ej1yB1CAThd4xUfgJu4touJROjvcD1zzlmLeat0fp2k5mCuiLKcTKi0vxKWiiopF9nvBBK+7ODPC7 buildfarm@nixos";

  hydra-queue-runner = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyM48VC5fpjJssLI8uolFscP4/iEoMHfkPoT9R3iE3OEjadmwa1XCAiXUoa7HSshw79SgPKF2KbGBPEVCascdAcErZKGHeHUzxj7v3IsNjObouUOBbJfpN4DR7RQT28PZRsh3TvTWjWnA9vIrSY/BvAK1uezFRuObvatqAPMrw4c0DK+JuGuCNkKDGHLXNSxYBc5Pmr1oSU7/BDiHVjjyLIsAMIc20+q8SjWswKqL1mY193mN7FpUMBtZrd0Za9fMFRII9AofEIDTOayvOZM6+/1dwRWZXM6jhE6kaPPF++yromHvDPBnd6FfwODKLvSF9BkA3pO5CqrD8zs7ETmrV hydra-queue-runner@chef";

  daniel_peebles = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsDWV0eYYYpGL3GRFL68mG4aw5xTTiEWp4AyheJEA0WciZb8SZY/RxoYv3l7ccAQYOF7vf4qxRXb5KEGV0tZkcsAc7qSn4Hcg9sSVp2xb1sWsvhGIlJV87QBk0r2UVnom7xSncot67M2u2MUxGWNrTEbXir5FjUcYQYIInwiDhJ7jPZaZDYY4LGs8pBQaVYCPdfxAnsWqZgJnqjO9lwkK7OgJajEkMKhK3xixqFPhKUDiJ3MxmRewHelHTBcxN8ghz5G3Rb+qmfg2ZQGxQWHN3l7IFqrHEcGHQAiKoYPXd2aL6iHgojPHWiWT7efvLVC6nnqlCwHtWyErI+IEeXBF3 copumpkin@work"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCkoril5uKjJohHvqz9Ys9R2rBH95MUb4Rxo5kcuRvEIwMranQ7xP5eU7rZqfv7elE1DLfMs19via+btUX3w8o4juYxzXjafnH6Mck5hYdvxNnErW6gsp0vGDQ0ruRCQx3UmOuC5Ld/wXY7iMQqOlxeLZF2dVCKP1+BSs37wLC7scXYu0U+wODprVpAsZIOwLP85w/uCNlC8wbvNDWG+Hx+XD/ml2ezQiNBRnh7Qo3QKgpUvVBO0d9z84g92D2H9IA+pEpJiWFcYKGEowKSVQVFCi5LoWRiz8XLKL+JeBt5mmmqjmJua6o8lXV7+nba//KCIkG+IWS4nwKQlpzZXc4H copumpkin@home"
  ];

  graham_christensen = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUDEJaYzYDc87ZutbpWifJ7h2Zk7winbS7/0Qyy/+yGwwJ8qP+Mvje6IwDwsnQuNZ8XZLKdGq7iDaXIa8hfvT8+wbwURxlUvJhhp1eQ6dI1/n6vtVFN0nOnCSPHdgmAQsNoqbt3RG7gGAPsLwAyn2MMfmbsdkz9JF1p7Lja+brNHmXkaVCU4Jq90f5Qv+TrwJNN+VIy4yxU3m7zvQZg0A5cG0bR5SZDMzceL4AsCtxpV+HBiG9tcBETn/Cw60bl7b7cGQFuZRlrZBPyIoyZ3be6Bscv0lOZSMBJzWyYTeOxNbIT2rR5yv8aSW/taQIcJ6LkZYszT6xe+52x/iAXGlL grahamc"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDY8wRHQtq9uBzdiAYzpSNmF+nmIHmW+AOeBTDNmdva+CFGIBbB56q7w6GCOhfXs8edrPY4qOcQGaOD0ussIvHnqkVfw8e6CbxnpXKeAuIz7+1V72AhLPzOkif4yPrI6tSYF5nvzq6U4Yk1qFnXiLQjkA1s4EcZH6V0KbHMsu7Mtv3Irspdn8KUI3j2UwZcssFu1EuLHhLNussziRQK9tOg9ixb0U1WXuUJn7Noh9odTAsAt6jLFdr5eN/IINgC9WQqvY/W94Tc2/z5TWR7z382pEkMBR/3sf+nYKA82069tagkyrtJ/YXi00CWU4vjpnMvwPEYcmtCddfCPi8ZIUrn grahamc"
  ];

  mac_keys = [
    # Unclear what to do with Rob's key which doesn't match above, and
    # the other key, presumably Eelco's
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDI6/qMXX80oWm+NyftRw45D+mRJwJQ6gexkUhp1OgZc3MuW6Zm2RO2IZHEjJLSMUndZebbznPmPPM58VxiyQnRYH2+hn+qCrwSsyCUxA8Gz6PpxeaeUMlpbsuXOPFbvBraDZEqIvx/gIK849nIahGz3EcfaY73lVRP+MrrVHBGyQmaOLoNfzrJp8rZfLqokQQXmG1d3DzjkIi87TZLgrdxQewpk/4eKBKf8FDnEYeV3ood78SPa3syS48al99Q7e8JyAEZJfyCQkUSUxgSizU5+se1A5seDJg2Vsqef1Ah23g/lTtSn93vtjjLvObvMJTSplBO8ttG/3ylIewWYER/ rbvermaa@nixos"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfNUQXdhu4tIC+oDtq12aKRw3mfHa1nP/sMRkE379bnByQWqgpr8cCsXaNsZIrM49Iv/cP2JxZT1S3K4kfp6ouvNN+rYubOrpHLt+NWhiI+1s5IpgZv21Ln1kANjo4jzKLTRfoGv1gWILTG1KSD8oTev1kE1p3GJph5pTVilzAW1uXNhkSpYVMIw6HwqPR4QN1UliD5FvAdz6FJ16E7/xhaVWdeEOcsYw2uRXBaY/rXkKtikscZ99wnOiCf6Gph2ahLkmZ/I3QmNq+xH+Xq6vpx6Kky0MKNm2zlh5tRDOd7Wd5N3sQpGAtHL4qGObq0N3VCtuJIL5eVRpZ5l5yNLsp"
  ] ++ graham_christensen ++ daniel_peebles;
};
  environment = concatStringsSep " "
    [
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];

   authorizedNixStoreKey = key:
      "command=\"${environment} ${config.nix.package}/bin/nix-store --serve --write\" ${key}";
in

{
  environment.systemPackages =
    [
      config.nix.package
    ];

  programs.bash.enable = true;
  programs.bash.enableCompletion = false;

  #services.activate-system.enable = true;

  services.nix-daemon.enable = true;

  nix.maxJobs = 4;
  nix.buildCores = 1;
  nix.gc.automatic = true;
  nix.gc.options = let
      gbFree = 25;
    in "--max-freed $((${toString gbFree} * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))";

  environment.etc."per-user/root/ssh/authorized_keys".text = concatStringsSep "\n"
    ([(authorizedNixStoreKey sshKeys.build-farm)
      (authorizedNixStoreKey sshKeys.hydra-queue-runner)
      ] ++ sshKeys.mac_keys);


  system.activationScripts.postActivation.text = ''
    printf "disabling spotlight indexing... "
    mdutil -i off -d / &> /dev/null
    mdutil -E / &> /dev/null
    echo "ok"

    printf "configuring ssh keys for hydra on the root account... "
    mkdir -p ~root/.ssh
    cp -f /etc/per-user/root/ssh/authorized_keys ~root/.ssh/authorized_keys
    chown root:wheel ~root ~root/.ssh ~root/.ssh/authorized_keys
    echo "ok"
  '';
}
