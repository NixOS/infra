# For the bits that are not nixops-able

For now this manages only resources in the main AWS account.

## Setup

Set the following environment variables:

AWS access key pair:

```sh
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

Fastly token from https://manage.fastly.com/account/personal/tokens with
global scope.

```sh
export FASTLY_API_KEY=...
```

## Usage

The first time the following command has to be run to initialize the state
file and plugins:

```sh
nix-shell --run "terraform init"
```

Then run the following command to diff the changes and then apply if approved:

```sh
nix-shell --run "terraform apply"
```

## Terraform workflow

Write the Terraform code and test the changes using `terraform validate`.

Before committing run `terraform fmt`. 

Once the code is ready to be deployed, create a new PR with the attached
output of `terraform plan`.

Once the PR is merged, run `terraform apply` to apply the changes.
