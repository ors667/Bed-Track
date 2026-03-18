# ---------------------------------------------------------------------------
# KMS — Customer-Managed Key (CMK) for PHI encryption
# All BedTrack data stores (DynamoDB, SQS, SNS, S3) use this key.
# 90-day automatic rotation; 30-day deletion window prevents accidental loss.
# ---------------------------------------------------------------------------

resource "aws_kms_key" "phi_cmk" {
  description             = "BedTrack CMK — encrypts all PHI data stores"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  multi_region            = false

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Lambda Service"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow SNS Service"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow SQS Service"
        Effect = "Allow"
        Principal = {
          Service = "sqs.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "phi_cmk" {
  name          = "alias/bedtrack-phi-cmk"
  target_key_id = aws_kms_key.phi_cmk.key_id
}
