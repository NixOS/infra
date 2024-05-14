output "cache" {
  value = {
    key    = aws_iam_access_key.fastly-cache-access.id
    secret = aws_iam_access_key.fastly-cache-access.secret
  }
  sensitive = true
}

output "fastlylogs" {
  value = module.fastlylogs
}

output "releases" {
  value = {
    key    = aws_iam_access_key.fastly-releases-access.id
    secret = aws_iam_access_key.fastly-releases-access.secret
  }
  sensitive = true
}
