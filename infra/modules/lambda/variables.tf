variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
}

variable "media_bucket_name" {
  description = "미디어 S3 버킷 이름"
  type        = string
}

variable "media_bucket_arn" {
  description = "미디어 S3 버킷 ARN"
  type        = string
}

variable "mediaconvert_role_arn" {
  description = "MediaConvert IAM Role ARN"
  type        = string
}

variable "callback_url" {
  description = "동영상 상태 콜백 URL"
  type        = string
}

variable "callback_secret" {
  description = "콜백 인증 시크릿"
  type        = string
  sensitive   = true
}
