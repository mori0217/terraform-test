# iam user
resource "aws_iam_user" "developer" {
  name = "developer"
}

resource "aws_iam_user_group_membership" "developer_grouop_membership" {
  user = aws_iam_user.developer.name
  groups = [
    aws_iam_group.developers.name
  ]
}

resource "aws_iam_user_login_profile" "developer_login_profile" {
  user                    = aws_iam_user.developer.name
  password_length         = 16
  password_reset_required = true
}