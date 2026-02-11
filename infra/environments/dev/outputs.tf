# Dev 환경 출력값 정의

output "instance_id" {
  description = "EC2 인스턴스 ID"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "EC2 퍼블릭 IP"
  value       = module.ec2.instance_public_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "web_url" {
  description = "웹 애플리케이션 URL"
  value       = "http://${module.ec2.instance_public_ip}"
}

output "rds_endpoint" {
  description = "RDS 엔드포인트"
  value       = module.rds.db_endpoint
}

output "cloudfront_domain" {
  description = "CloudFront 도메인 (HLS 스트리밍)"
  value       = module.media.cloudfront_domain
}

output "ecr_backend_url" {
  description = "Backend ECR 리포지토리 URL"
  value       = module.ecr.backend_repository_url
}

output "ecr_frontend_url" {
  description = "Frontend ECR 리포지토리 URL"
  value       = module.ecr.frontend_repository_url
}
