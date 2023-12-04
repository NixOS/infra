# Get the list of files from the releases
resource "aws_s3_bucket" "releases_inventory" {
  bucket_prefix = "nix-releases-inventory2"

  lifecycle_rule {
    enabled = true

    # Only keep the last 30 days
    expiration {
      days = 30
    }
  }
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

