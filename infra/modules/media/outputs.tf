output "bucket_name" {
  description = "S3 미디어 버킷 이름"
  value       = aws_s3_bucket.media.id
}

output "bucket_arn" {
  description = "S3 미디어 버킷 ARN"
  value       = aws_s3_bucket.media.arn
}

output "cloudfront_domain" {
  description = "CloudFront 도메인"
  value       = aws_cloudfront_distribution.media.domain_name
}

output "mediaconvert_role_arn" {
  description = "MediaConvert IAM Role ARN"
  value       = aws_iam_role.mediaconvert.arn
}
