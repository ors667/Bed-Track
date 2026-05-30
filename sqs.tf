# ---------------------------------------------------------------------------
# SQS — Bed status event queue
# Bed status change events (occupied, available, cleaning, maintenance)
# are published here by ward systems and consumed by the BedTrack Lambda.
# SQS is inherently multi-AZ — messages are redundantly stored across
# multiple AZs within the region.
# DLQ retains unprocessable messages for 7 days for operational review.
# ---------------------------------------------------------------------------

resource "aws_sqs_queue" "bed_events_dlq" {
  name                       = "bedtrack-bed-events-dlq"
  message_retention_seconds  = 604800  # 7 days
  kms_master_key_id          = aws_kms_key.phi_cmk.arn
  kms_data_key_reuse_period_seconds = 300
  tags = {
    app              = "bedtrack"
    data-sensitivity = "phi"
    env              = "production"
    hipaa-scope      = "true"
  }
}

resource "aws_sqs_queue" "bed_events" {
  name                       = "bedtrack-bed-events"
  visibility_timeout_seconds = 90        # Must exceed Lambda timeout
  message_retention_seconds  = 86400     # 1 day — processed events archived to S3
  receive_wait_time_seconds  = 20        # Long polling reduces empty receives
  kms_master_key_id          = aws_kms_key.phi_cmk.arn
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.bed_events_dlq.arn
    maxReceiveCount     = 3
  })
  tags = {
    app                = "bedtrack"
    "data-sensitivity" = "phi"
    env                = "production"
    "hipaa-scope"      = "true"
  }
}
