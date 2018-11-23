# Client setup

This document contains the machine setup of the infrastructure member.

## Dependencies

Install Nix obviously :)

## SSH configuration

Add the following to the `~/.ssh/config` file:

```
Host bastion.nixos.org
  User deploy
  SendEnv FASTLY_API_KEY AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
  ForwardAgent yes
  IdentityFile ~/.ssh/nixos_rsa
```
