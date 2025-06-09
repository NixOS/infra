# Get the list of files from the releases
resource "aws_s3_bucket" "releases_inventory" {
  bucket_prefix = "nix-releases-inventory2"
}

resource "aws_s3_bucket_lifecycle_configuration" "releases_inventory" {
  bucket = aws_s3_bucket.releases_inventory.id

  transition_default_minimum_object_size = "varies_by_storage_class"

  rule {
    id     = "tf-s3-lifecycle-20231029182032300100000002"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }
  }
}

import {
  to = aws_s3_bucket_lifecycle_configuration.releases_inventory
  id = aws_s3_bucket.releases_inventory.id
}

resource "aws_s3_bucket_inventory" "releases_inventory" {
  bucket = aws_s3_bucket.releases.id
  name   = "nix-releases-inventory"

  included_object_versions = "Current"

  optional_fields = [
    "ETag",
    "LastModifiedDate",
    "Size",
    "StorageClass",
  ]

  schedule {
    frequency = "Daily"
  }

  destination {
    bucket {
      account_id = "080433136561"
      format     = "Parquet"
      bucket_arn = aws_s3_bucket.releases_inventory.arn
    }
  }
}
