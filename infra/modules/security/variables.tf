# 보안 모듈 입력 변수
variable "vpc_id" {
  description = "보안 그룹을 생성할 VPC ID"
  type        = string
}

variable "my_ip" {
  description = "SSH 접속을 허용할 IP (CIDR 형식)"
  type        = string
}

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
}
