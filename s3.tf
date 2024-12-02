# Generate a UUID for a unique S3 bucket name
resource "random_uuid" "s3_bucket_uuid" {}

# Create the S3 bucket with force deletion enabled
resource "aws_s3_bucket" "private_bucket" {
  bucket = "private-bucket-${random_uuid.s3_bucket_uuid.result}"

  # Enable force deletion of the bucket
  force_destroy = true

  tags = {
    Name = "private-s3-bucket"
  }
}

# Separate resource for server-side encryption configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
  }
}

# Set up a lifecycle configuration to transition objects to STANDARD_IA after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.private_bucket.id

  rule {
    id     = "TransitionRule"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}
 