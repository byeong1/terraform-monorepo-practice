variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
}

variable "multipart_upload_abort_days" {
  description = "미완성 멀티파트 업로드 자동 삭제까지의 일수"
  type        = number
  default     = 1
}
