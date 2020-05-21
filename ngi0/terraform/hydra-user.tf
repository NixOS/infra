resource "aws_iam_user" "hydra" {
  provider = aws
  name = "hydra"
}

resource "aws_iam_access_key" "hydra" {
  user = aws_iam_user.hydra.name
}
