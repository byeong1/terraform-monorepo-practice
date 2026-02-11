output "tfstate_bucket_name" {
  description = "Terraform 상태 저장 S3 버킷 이름"
  value       = aws_s3_bucket.tfstate.bucket
}

output "tfstate_bucket_arn" {
  description = "Terraform 상태 저장 S3 버킷 ARN"
  value       = aws_s3_bucket.tfstate.arn
}

output "tflock_table_name" {
  description = "Terraform 상태 잠금 DynamoDB 테이블 이름"
  value       = aws_dynamodb_table.tflock.name
}
