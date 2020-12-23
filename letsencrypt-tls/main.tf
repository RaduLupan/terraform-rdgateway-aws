provider "aws" {
  region = var.region
}

locals {
  s3_name = "${var.s3_prefix}-${var.environment}-${lower(random_string.random.result)}"
  s3_bucket_name = split(".", aws_s3_bucket.certbot.bucket_domain_name)[0]

  common_tags = {
    terraform   = "true"
    environment = var.environment
    role        = "letsencrypt-tls"
  }
}

# The random string needed for injecting randomness in the name of the S3 bucket.
resource "random_string" "random" {
  length  = 12
  special = false
}

# S3 bucket that holds the certbot code.
resource "aws_s3_bucket" "certbot" {
  bucket = local.s3_name
  acl    = "private"

  force_destroy = "true"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    id      = "ExpireOldVersionsAfter30Days"
    enabled = true

    noncurrent_version_expiration {
      days = 30
    }
  }

  tags = local.common_tags
}

# Upload the certbot code to S3 bucket.
resource "aws_s3_bucket_object" "certbot_upload" {
  bucket = local.s3_bucket_name
  key    = "certbot-0.27.1.zip"
  source = "./certbot-0.27.1.zip"
  etag   = filemd5("./certbot-0.27.1.zip")
}

# Lambda execution role
resource "aws_iam_role" "execution" {
  name               = "letsencrypt-certbot-lambda-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_execution.json

  tags = local.common_tags
}

# Trust policy for the IAM role
data "aws_iam_policy_document" "assume_execution" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
