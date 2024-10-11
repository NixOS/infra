Non-critical-infra
================

This folder of the repository contains all files relative to the non-critical infra team. Machines managed by that specific configuration are distinct from the ones used in the rest of that repository and used to host services useful to the general Nix/NixOS community.


## For the users 

### I would like my project hosted by this infrastructure
Open a PR or an issue, and members of the infra team will tell you if this infrastructure is suitable to the project!

### I would like to join the team
Come and talk to us on matrix: #infra:nixos.org


## For the contributors

### Secret access 
Secret access is on a "need to have" basis. If you think you need access to the secrets, please add your key to the `.sops.yaml` file on a PR and ping people that already have access for them to run the `updatekeys` command.
