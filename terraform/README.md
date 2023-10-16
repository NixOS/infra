# For the bits that are not nixops-able

This terraform root module manages:
* the resource in the AWS main account (S3 buckets)
* Fastly
* Netlify DNS

## Setup

In order to use this, make sure to install direnv and Nix with flakes enabled.

Then copy the `.envrc.local.template` to `.envrc.local`, and fill in the
related keys.

> FIXME: Unset the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY env vars if
>        they are already set. Those have been replaced by AWS SSO.

Then run `direnv allow` to load the environment with the runtime dependencies.

Run `aws configure sso` to acquire a temporary token:

* Leave `SSO session name` **empty** (this is needed for legacy SSO).
* Select account `LBNixOS_Dev_PDX (080433136561)`.
* Select role `AWSAdministratorAccess`.
* Leave all the rest with the default options.

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
