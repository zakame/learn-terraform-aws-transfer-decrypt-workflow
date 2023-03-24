provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "test_bucket" {
  bucket_prefix = "aws-transfer-test-"

  force_destroy = true
}

resource "aws_transfer_server" "test" {
  security_policy_name = "TransferSecurityPolicy-2020-06"

  logging_role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AWSTransferLoggingAccess"
  workflow_details {
    on_upload {
      workflow_id    = aws_transfer_workflow.decrypt.id
      execution_role = aws_iam_role.pgp_decrypt.arn
    }
  }

  force_destroy = true
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "transfer_user" {
  name               = "aws-transfer-test-transfer-user-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "transfer_user" {
  statement {
    sid = "AllowListingOfUserFolder"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    effect    = "Allow"
    resources = [aws_s3_bucket.test_bucket.arn]
  }
  statement {
    sid = "HomeDirObjectAccess"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObjectVersion",
      "s3:GetObjectACL",
      "s3:PutObjectACL"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.test_bucket.arn}/*"]
  }
}

resource "aws_iam_role_policy" "transfer_user" {
  name   = "aws-transfer-test-transfer-user-iam-policy"
  role   = aws_iam_role.transfer_user.id
  policy = data.aws_iam_policy_document.transfer_user.json
}

resource "aws_transfer_user" "transfer_user" {
  server_id = aws_transfer_server.test.id
  user_name = "test"
  role      = aws_iam_role.transfer_user.arn

  home_directory_type = "LOGICAL"
  home_directory_mappings {
    entry  = "/"
    target = "/${aws_s3_bucket.test_bucket.id}/test"
  }
}

resource "aws_transfer_ssh_key" "transfer_user" {
  server_id = aws_transfer_server.test.id
  user_name = aws_transfer_user.transfer_user.user_name
  body      = var.transfer_user_key
}

resource "aws_secretsmanager_secret" "pgp_key" {
  name = "aws/transfer/${aws_transfer_server.test.id}/@pgp-default"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "pgp_key" {
  secret_id     = aws_secretsmanager_secret.pgp_key.id
  secret_string = jsonencode(var.transfer_pgp_secret)
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "pgp_decrypt" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    effect    = "Allow"
    resources = [aws_s3_bucket.test_bucket.arn]
  }
  statement {
    sid = "HomeDirObjectAccess"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObjectVersion",
      "s3:DeleteObject",
      "s3:GetObjectVersion"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.test_bucket.arn}/*"]
  }
  statement {
    sid       = "Decrypt"
    actions   = ["secretsmanager:GetSecretValue"]
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:aws/transfer/*"]
  }
}

resource "aws_iam_policy" "pgp_decrypt" {
  name = "aws-transfer-test-workflow-iam-policy"

  policy = data.aws_iam_policy_document.pgp_decrypt.json
}

resource "aws_iam_role" "pgp_decrypt" {
  name               = "aws-transfer-test-workflow-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSTransferFullAccess",
    aws_iam_policy.pgp_decrypt.arn
  ]
}

resource "aws_transfer_workflow" "decrypt" {
  steps {
    type = "DECRYPT"

    decrypt_step_details {
      type = "PGP"

      source_file_location = "$${original.file}"
      destination_file_location {
        s3_file_location {
          bucket = aws_s3_bucket.test_bucket.id
          key    = "$${Transfer:UserName}/"
        }
      }
    }
  }
}
