# ---------------------------------------------------------------------------
# SNS — Bed availability alert topic
# Published by Lambda when a bed transitions to available status in a
# unit that has been flagged as high-demand (e.g. ICU, ED overflow).
# Notifies care coordinators and bed management team.
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "bed_alerts" {
  name              = "bedtrack-bed-alerts"
  display_name      = "BedTrack Availability Alerts"
  kms_master_key_id = aws_kms_key.phi_cmk.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceInTransitEncryption"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sns:Publish"
        Resource  = "*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "bed_alerts_email" {
  topic_arn = aws_sns_topic.bed_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
