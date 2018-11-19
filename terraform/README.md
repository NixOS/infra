# For the bits that are not nixops-able

For now this manages only resources in the main AWS account.

## Usage

Make sure to have the AWS key-pair in the environment, in
`~/.aws/credentials` or as the EC2 metadata service.

The first time the following command has to be run to initialize the state
file and plugins:

```
nix-shell --run "terraform init"
```

Then run the following command to diff the changes and then apply if approved:

```
nix-shell --run "terraform apply"
```

## Terraform workflow

Write the Terraform code and test the changes using `terraform validate`.

Before committing run `terraform fmt`. 

Once the code is ready to be deployed, create a new PR with the attached
output of `terraform plan`.

Once the PR is merged, run `terraform apply` to apply the changes.
