# For the bits that are not nixops-able

This module is for superadmins in the team.

This terraform root module manages:
* IAM roles

## Setup

In order to use this, make sure to install direnv and Nix with flakes enabled.

Then run `direnv allow` to load the environment with the runtime dependencies.

Run `aws sso login` to acquire a temporary token.

## Usage

The first time the following command has to be run to initialize the state
file and plugins:

```sh
terraform init
```

Then run the following command to diff the changes and then apply if approved:

```sh
terraform apply
```

## Terraform workflow

Write the Terraform code and test the changes using `terraform validate`.

Before committing run `terraform fmt`. 

Once the code is ready to be deployed, create a new PR with the attached
output of `terraform plan`.

Once the PR is merged, run `terraform apply` to apply the changes.
