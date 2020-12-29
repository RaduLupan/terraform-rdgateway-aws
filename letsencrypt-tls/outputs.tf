output "s3_bucket_certbot" {
  description = "The name of the S3 bucket that holds the certbot code for Lambda and the scripts for the EC2 instance"
  value       = aws_s3_bucket.certbot.bucket
}

output "s3_bucket_tls" {
  description = "The name of the S3 bucket that holds the Letsencrypt TLS certificates"
  value       = aws_s3_bucket.letsencrypt_tls.bucket
}

output "s3_folder_tls" {
  description = "The name of the S3 folder where the TLS certificates are deposited by the certbot Lambda"
  value       = local.s3_folder_tls
}

output "lambda_certbot_arn" {
  description = "The ARN of the certbot Lambda function"
  value       = aws_lambda_function.le_certbot_lambda.arn
}

output "tls_domains" {
  description = "The domains covered by TLS certificate"
  value       = local.domains
}

