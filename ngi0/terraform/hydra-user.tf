resource "aws_iam_user" "hydra" {
  provider = aws
  name = "hydra"
}

resource "aws_iam_access_key" "hydra" {
  user = aws_iam_user.hydra.name
}

resource "aws_iam_user_policy" "hydra" {
  name = "test"
  user = aws_iam_user.hydra.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1590080325117",
      "Action": "s3:*",
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
