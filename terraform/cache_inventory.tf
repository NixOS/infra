# Get the list of files from the cache
resource "aws_s3_bucket" "cache_inventory" {
  provider = aws.us
  bucket   = "nix-cache-inventory"
}

resource "aws_s3_bucket_lifecycle_configuration" "cache_inventory" {
  provider = aws.us
  bucket   = aws_s3_bucket.cache_inventory.id

  transition_default_minimum_object_size = "varies_by_storage_class"

  rule {
    id     = "tf-s3-lifecycle-20231017200421961900000001"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # Only keep the last 30 days
    expiration {
      days = 30
    }
  }
}

import {
  to = aws_s3_bucket_lifecycle_configuration.cache_inventory
  id = aws_s3_bucket.cache_inventory.id
}

resource "aws_s3_bucket_inventory" "cache_inventory" {
  provider = aws.us

  bucket = aws_s3_bucket.cache.id
  name   = "nix-cache-inventory"

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
      bucket_arn = aws_s3_bucket.cache_inventory.arn
    }
  }
}
