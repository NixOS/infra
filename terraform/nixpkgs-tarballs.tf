resource "aws_s3_bucket" "nixpkgs-tarballs" {
  bucket = "nixpkgs-tarballs"
  region = "eu-west-1"
  acl    = "public-read"

  website {
    index_document = "index.html"
  }
}

resource "aws_cloudfront_distribution" "nixpkgs-tarballs" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class = "PriceClass_All"
  aliases = ["tarballs.nixos.org"]

  origin {
    domain_name = "${aws_s3_bucket.nixpkgs-tarballs.website_domain}"
    origin_id   = "${aws_s3_bucket.nixpkgs-tarballs.name}"
  }

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id   = "${aws_s3_bucket.nixpkgs-tarballs.name}"
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl = 31536000

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
