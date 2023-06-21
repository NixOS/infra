# Bastion

The entry-point to our infra. Welcome.

## Deploy

To deploy new changes, use `AWS_PROFILE=lb-nixos terraform apply` from a trusted machine.

## Fallback

In case terraform is broken, run the `./deploy.sh` script from a NixOS
machine. It depends on `nixos-rebuild` under the hood.

## Common issues

* make sure that your system has Nix 2.4+ installed on it.
* make sure that ssh-agent is running and that the bastion key is loaded in it.
