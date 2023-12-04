resource "aws_iam_user" "s3-upload-cache" {
  name = "s3-upload-cache"
}

resource "aws_iam_user" "s3-upload-releases" {
  name = "s3-upload-releases"
}

resource "aws_iam_user" "s3-upload-tarballs" {
  name = "s3-upload-tarballs"
}
