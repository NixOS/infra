# For the bits that are not nixops-able

This terraform root module manages:

- the resource in the AWS main account (S3 buckets)
- Fastly
- Netlify DNS

## Setup

In order to use this, make sure to install direnv and Nix with flakes enabled.

Then copy the `.envrc.local.template` to `.envrc.local`, and fill in the related
keys.

> FIXME: Unset the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY env vars if they
> are already set. Those have been replaced by AWS SSO.

Then run `direnv allow` to load the environment with the runtime dependencies.

Run `aws sso login` to acquire a temporary token.

## Usage

We use opentofu, which is a fork of https://www.terraform.io/ maintained by the
Linux foundation.

Then run the following command to diff the changes and then apply if approved:

```sh
./tf.sh apply
```

## Terraform workflow

Write the Tofu code and test the changes using `./tf.sh validate`.

Before committing run `nix fmt`.

Once the code is ready to be deployed, create a new PR with the attached output
of `./tf.sh plan`.

Once the PR is merged, run `./tf.sh apply` to apply the changes.

## Upgrade from terraform to opentofu

If you have used terraform, you may have to delete .terraform in this directory
once to fixup provider registry addresses.
