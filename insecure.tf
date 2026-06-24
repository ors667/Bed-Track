# KEN-318 E2E: intentionally insecure bucket to exercise PR-analysis "new risk"
# detection. Public-readable, no server-side encryption, public access block
# disabled — the inverse of the hardened audit_logs bucket in s3.tf.
resource "aws_s3_bucket" "ken318_public_dump" {
  bucket = "${var.account_id}-bedtrack-ken318-public-dump"
}

resource "aws_s3_bucket_public_access_block" "ken318_public_dump" {
  bucket                  = aws_s3_bucket.ken318_public_dump.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "ken318_public_dump" {
  bucket = aws_s3_bucket.ken318_public_dump.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicRead"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.ken318_public_dump.arn}/*"
    }]
  })
}
