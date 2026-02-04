# 보안 모듈 출력값
output "security_group_id" {
  description = "생성된 보안 그룹 ID"
  value       = aws_security_group.main.id
}

output "db_security_group_id" {
  description = "DB 보안 그룹 ID"
  value       = aws_security_group.db.id
}
