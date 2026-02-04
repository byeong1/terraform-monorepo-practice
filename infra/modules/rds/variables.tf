variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "subnet_ids" {
  description = "DB 서브넷 그룹에 사용할 서브넷 ID 목록"
  type        = list(string)
}

variable "security_group_id" {
  description = "RDS에 연결할 보안 그룹 ID"
  type        = string
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "DB 마스터 사용자 이름"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "DB 마스터 비밀번호"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "할당 스토리지 크기 (GB)"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "MySQL 엔진 버전"
  type        = string
  default     = "8.0"
}
