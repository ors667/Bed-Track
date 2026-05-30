# ---------------------------------------------------------------------------
# S3 — Bed event audit log archive
# Processed bed status events are written here by Lambda for long-term
# audit retention. Versioning and CMK encryption enforced.
# Retention aligns with HIPAA 6-year minimum for operational records.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "audit_logs" {
  bucket        = "${var.account_id}-bedtrack-audit-logs"
  force_destroy = false
  tags = {
    app              = "bedtrack"
    data-sensitivity = "phi"
    env              = "production"
    hipaa-scope      = "true"
  }
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.phi_cmk.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket                  = aws_s3_bucket.audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    id     = "hipaa-retention-6yr"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2190  # 6 years — HIPAA minimum for operational records
    }
  }
}
