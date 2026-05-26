# ---------------------------------------------------------------------------
# IAM — Lambda execution role
# Scoped strictly to the resources BedTrack Lambda needs:
# SQS (consume events), DynamoDB (read/write bed status),
# SNS (publish alerts), S3 (write audit logs), KMS (decrypt).
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bedtrack_lambda" {
  name               = "bedtrack-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  description        = "Least-privilege execution role for BedTrack Lambda"
  tags = {
    app              = "bedtrack"
    env              = "production"
    data-sensitivity = "phi"
    hipaa-scope      = "true"
  }
}

resource "aws_iam_role_policy" "bedtrack_lambda" {
  name = "bedtrack-lambda-policy"
  role = aws_iam_role.bedtrack_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SQSConsume"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [aws_sqs_queue.bed_events.arn]
      },
      {
        Sid    = "DynamoDBReadWrite"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.bed_status.arn,
          "${aws_dynamodb_table.bed_status.arn}/index/*"
        ]
      },
      {
        Sid      = "SNSPublish"
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = [aws_sns_topic.bed_alerts.arn]
      },
      {
        Sid    = "S3AuditWrite"
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = ["${aws_s3_bucket.audit_logs.arn}/events/*"]
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = [aws_kms_key.phi_cmk.arn]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/bedtrack-processor:*"
      },
      {
        Sid    = "VPCNetworking"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}
