# Dev 환경 변수 정의

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "terraform-practice"
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "퍼블릭 서브넷 CIDR 블록"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
  default     = "ami-0f1e61a80c7ab943e"
}

variable "my_ip" {
  description = "SSH 접속 허용 IP (CIDR 형식)"
  type        = string
}

variable "db_password" {
  description = "데이터베이스 비밀번호"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "RDS 마스터 사용자 이름"
  type        = string
  default     = "admin"
}

variable "db_name" {
  description = "RDS 데이터베이스 이름"
  type        = string
  default     = "appdb"
}
