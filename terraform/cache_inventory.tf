# Get the list of files from the cache
resource "aws_s3_bucket" "cache_inventory" {
  provider = aws.us
  bucket   = "nix-cache-inventory"

  lifecycle_rule {
    enabled = true

    # Only keep the last 30 days
    expiration {
      days = 30
    }
  }
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

