resource "aws_s3_bucket" "inventory" {
  provider = aws.us
  bucket = "nixos-inventory"

  lifecycle_rule {
    enabled = true
    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_inventory" "cache-inventory" {
  provider = aws.us
  bucket = aws_s3_bucket.cache.id
  name   = "WeeklyInventory"

  included_object_versions = "All"

  optional_fields = ["Size", "StorageClass", "LastModifiedDate"]

  schedule {
    frequency = "Weekly"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.inventory.arn
    }
  }
}

resource "aws_s3_bucket" "inventory-eu" {
  bucket = "nixos-inventory-eu"

  lifecycle_rule {
    enabled = true
    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_inventory" "tarballs-inventory" {
  bucket = aws_s3_bucket.nixpkgs-tarballs.id
  name   = "WeeklyInventory"

  included_object_versions = "All"

  optional_fields = ["Size", "StorageClass", "LastModifiedDate"]

  schedule {
    frequency = "Weekly"
  }

  destination {
    bucket {
      format     = "CSV"
      bucket_arn = aws_s3_bucket.inventory-eu.arn
    }
  }
}
