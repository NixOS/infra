# User & permission management

This module is for superadmins in the team.

This terraform root module manages:
* IAM roles
* fastly log module
* infrastructure for archeologist team

## Setup

In order to use this, make sure to install direnv and Nix with flakes enabled.

Then run `direnv allow` to load the environment with the runtime dependencies.

Run `aws sso login` to acquire a temporary token.

## Usage

We use opentofu, which is a fork of https://www.terraform.io/ maintained by the Linux foundation.

Then run the following command to diff the changes and then apply if approved:

```sh
./tf.sh apply
```

## Terraform workflow

Write the Tofu code and test the changes using `./tf.sh validate`.

Before committing run `nix fmt`.

Once the code is ready to be deployed, create a new PR with the attached
output of `./tf.sh plan`.

Once the PR is merged, run `./tf.sh apply` to apply the changes.
