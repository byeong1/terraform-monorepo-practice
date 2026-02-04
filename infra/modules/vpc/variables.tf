# VPC 모듈 입력 변수

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "public_subnet_cidr" {
  description = "퍼블릭 서브넷 CIDR 블록"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
}

variable "project_name" {
  description = "프로젝트 이름 (리소스 태깅용)"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 블록 목록 (최소 2개 AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "사용할 가용영역 접미사 목록"
  type        = list(string)
  default     = ["a", "c"]
}
