# ---------------------------------------------------------------------------
# Lambda — BedTrack event processor
# Triggered by SQS messages from ward systems. For each bed status event:
#   1. Validates and parses the bed status payload
#   2. Writes updated bed state to DynamoDB
#   3. Publishes SNS alert if bed transitions to available in a high-demand unit
#   4. Archives the processed event to the S3 audit log bucket
#
# Deployed into private subnets across multiple AZs for high availability.
# Lambda automatically distributes execution across the supplied subnets,
# providing active-active AZ redundancy with no additional configuration.
# Environment variables encrypted at rest using the PHI CMK.
# ---------------------------------------------------------------------------

resource "aws_lambda_function" "bedtrack_processor" {
  function_name = "bedtrack-processor"
  role          = aws_iam_role.bedtrack_lambda.arn
  handler       = "handler.process_bed_event"
  runtime       = "python3.12"
  filename      = "bedtrack_processor.zip"
  timeout       = 60 # Must be less than SQS visibility timeout (90s)
  memory_size   = 256
  kms_key_arn   = aws_kms_key.phi_cmk.arn

  # Multi-AZ deployment — Lambda places execution environments across
  # all subnets provided, achieving active-active AZ redundancy
  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  environment {
    variables = {
      BED_STATUS_TABLE = aws_dynamodb_table.bed_status.name
      ALERTS_TOPIC_ARN = aws_sns_topic.bed_alerts.arn
      AUDIT_BUCKET     = aws_s3_bucket.audit_logs.bucket
      ENVIRONMENT      = var.environment
    }
  }

  # SQS trigger — batch size of 10 with report_batch_item_failures
  # allows partial batch success; failed messages retry individually
  # rather than reprocessing the entire batch
  event_source_mapping_config = null # Defined via aws_lambda_event_source_mapping below

  tracing_config {
    mode = "Active" # X-Ray tracing for end-to-end request visibility
  }

  depends_on = [aws_iam_role_policy.bedtrack_lambda]
  tags = {
    app              = "bedtrack"
    env              = "production"
    data-sensitivity = "phi"
    hipaa-scope      = "true"
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn                   = aws_sqs_queue.bed_events.arn
  function_name                      = aws_lambda_function.bedtrack_processor.arn
  batch_size                         = 10
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]
  tags = {
    app              = "bedtrack"
    env              = "production"
    data-sensitivity = "phi"
    hipaa-scope      = "true"
  }
}

resource "aws_lambda_function" "isolated_processor" {
  function_name = "isolated_processor"
  role          = aws_iam_role.bedtrack_lambda.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  filename      = "payload.zip"
  kms_key_arn   = aws_kms_key.phi_cmk.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }
  tracing_config = {
    mode = "Active"
  }
  tags = {
    app              = "bedtrack"
    env              = "production"
    data-sensitivity = "phi"
    hipaa-scope      = "true"
  }
}
