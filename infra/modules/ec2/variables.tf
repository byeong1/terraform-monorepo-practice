# EC2 모듈 입력 변수

variable "ami_id" {
  description = "EC2 인스턴스 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
}

variable "subnet_id" {
  description = "EC2 인스턴스를 배치할 서브넷 ID"
  type        = string
}

variable "security_group_id" {
  description = "EC2 인스턴스에 연결할 보안 그룹 ID"
  type        = string
}

variable "project_name" {
  description = "프로젝트 이름 (리소스 태그용)"
  type        = string
}

variable "db_password" {
  description = "데이터베이스 비밀번호"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "데이터베이스 호스트 (RDS 엔드포인트)"
  type        = string
}

variable "db_username" {
  description = "데이터베이스 사용자 이름"
  type        = string
  default     = "admin"
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "appdb"
}
