resource "aws_iam_user" "fastly-cache-access" {
  name = "fastly-cache-access"
}

resource "aws_iam_access_key" "fastly-cache-access" {
  user = aws_iam_user.fastly-cache-access.name
}
