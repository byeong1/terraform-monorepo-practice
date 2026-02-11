output "trigger_mediaconvert_arn" {
  description = "trigger-mediaconvert Lambda ARN"
  value       = aws_lambda_function.trigger_mediaconvert.arn
}

output "update_video_status_arn" {
  description = "update-video-status Lambda ARN"
  value       = aws_lambda_function.update_video_status.arn
}
