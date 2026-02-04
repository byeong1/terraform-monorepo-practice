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
