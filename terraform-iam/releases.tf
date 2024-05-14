resource "aws_iam_user" "fastly-releases-access" {
  name = "fastly-releases-access"
}

resource "aws_iam_access_key" "fastly-releases-access" {
  user = aws_iam_user.fastly-releases-access.name
}
