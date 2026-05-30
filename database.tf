# ---------------------------------------------------------------------------
# DynamoDB — Bed status table
# Stores real-time bed availability state per unit and ward.
# PAY_PER_REQUEST billing mode provides automatic multi-AZ replication
# across three availability zones with no capacity planning required.
# Point-in-time recovery enabled for 35-day restore window per HIPAA policy.
# ---------------------------------------------------------------------------

resource "aws_dynamodb_table" "bed_status" {
  name         = "bedtrack-bed-status"
  billing_mode = "PAY_PER_REQUEST"  # Auto-scales; data replicated across 3 AZs
  hash_key     = "bed_id"
  range_key    = "updated_at"

  attribute {
    name = "bed_id"
    type = "S"
  }

  attribute {
    name = "updated_at"
    type = "S"
  }

  attribute {
    name = "ward_id"
    type = "S"
  }

  # GSI allows queries by ward — e.g. "all beds in ICU"
  global_secondary_index {
    name            = "ward-updated-index"
    hash_key        = "ward_id"
    range_key       = "updated_at"
    projection_type = "ALL"
  }

  # PITR provides continuous backups with 35-day restore window
  point_in_time_recovery {
    enabled = true
  }

  # CMK encryption at rest — consistent with all other PHI stores
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.phi_cmk.arn
  }

  # TTL on entries older than 90 days — operational data does not require
  # long-term retention in the live table; archived to S3 audit log bucket
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  deletion_protection_enabled = true
  tags = {
    app              = "bedtrack"
    data-sensitivity = "phi"
    env              = "production"
    hipaa-scope      = "true"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_depth_alarm" {
  alarm_name          = "bedtrack-${var.environment}-dlq-depth"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Alert when poison pill messages are moved to the BedTrack DLQ"
  alarm_actions       = [aws_sns_topic.bed_alerts.arn]

  dimensions = {
    QueueName = aws_sqs_queue.bed_events_dlq.name
  }
}
resource "aws_s3_bucket_policy" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyAccessOutsideVPC"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.audit_logs.arn,
          "${aws_s3_bucket.audit_logs.arn}/*"
        ]
        Condition = {
          StringNotEquals = {
            "aws:SourceVpc" = var.vpc_id
          }
        }
      }
    ]
  })
}