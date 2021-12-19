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
  SetEnv GIT_AUTHOR_NAME="Your Name" GIT_COMMITTER_NAME="Your Name" GIT_AUTHOR_EMAIL="your.name@example.com" GIT_COMMITTER_EMAIL="your.name@example.com"
  ForwardAgent yes
  IdentityFile ~/.ssh/nixos_rsa
```
