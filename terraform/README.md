# For the bits that are not nixops-able

For now this manages only resources in the main AWS account.

## Usage

Make sure to have the AWS key-pair in the environment, in
`~/.aws/credentials` or as the EC2 metadata service.

Then run:

```
nix-shell --run "terraform apply"
```

## TODO

* Add remote state
* Add cert manager
* Manage the S3 buckets and CloudFront distributions
* Manage the VPCs and Security Groups

