output "bed_events_queue_url" {
  description = "SQS queue URL for ward systems to publish bed status events"
  value       = aws_sqs_queue.bed_events.url
}

output "bed_events_dlq_url" {
  description = "SQS dead-letter queue URL for unprocessable events"
  value       = aws_sqs_queue.bed_events_dlq.url
}

output "bed_status_table_name" {
  description = "DynamoDB table name for real-time bed status"
  value       = aws_dynamodb_table.bed_status.name
}

output "alerts_topic_arn" {
  description = "SNS topic ARN for bed availability alerts"
  value       = aws_sns_topic.bed_alerts.arn
}

output "audit_log_bucket" {
  description = "S3 bucket name for bed event audit log archive"
  value       = aws_s3_bucket.audit_logs.bucket
}

output "lambda_function_name" {
  description = "BedTrack processor Lambda function name"
  value       = aws_lambda_function.bedtrack_processor.function_name
}

output "kms_key_arn" {
  description = "PHI CMK ARN used across all BedTrack data stores"
  value       = aws_kms_key.phi_cmk.arn
}

# KEN-317 e2e: no-op comment — no resource change (validates D2 PR diff)
