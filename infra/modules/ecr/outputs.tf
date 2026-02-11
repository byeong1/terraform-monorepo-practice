output "backend_repository_url" {
  description = "Backend ECR 리포지토리 URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "frontend_repository_url" {
  description = "Frontend ECR 리포지토리 URL"
  value       = aws_ecr_repository.frontend.repository_url
}
