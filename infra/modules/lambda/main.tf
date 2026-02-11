# Lambda IAM Role
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_custom" {
  name = "${var.project_name}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "mediaconvert:CreateJob",
          "mediaconvert:DescribeEndpoints"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = var.mediaconvert_role_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${var.media_bucket_arn}/*"
      }
    ]
  })
}

# Lambda 소스 코드 패키징
data "archive_file" "trigger_mediaconvert" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/trigger-mediaconvert/index.py"
  output_path = "${path.module}/../../lambda/trigger-mediaconvert.zip"
}

data "archive_file" "update_video_status" {
  type        = "zip"
  source_file = "${path.module}/../../lambda/update-video-status/index.py"
  output_path = "${path.module}/../../lambda/update-video-status.zip"
}

# Lambda: trigger-mediaconvert
resource "aws_lambda_function" "trigger_mediaconvert" {
  function_name    = "${var.project_name}-trigger-mediaconvert"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 60
  filename         = data.archive_file.trigger_mediaconvert.output_path
  source_code_hash = data.archive_file.trigger_mediaconvert.output_base64sha256

  environment {
    variables = {
      MEDIACONVERT_ROLE_ARN = var.mediaconvert_role_arn
      DESTINATION_BUCKET    = var.media_bucket_name
    }
  }
}

# Lambda: update-video-status
resource "aws_lambda_function" "update_video_status" {
  function_name    = "${var.project_name}-update-video-status"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 30
  filename         = data.archive_file.update_video_status.output_path
  source_code_hash = data.archive_file.update_video_status.output_base64sha256

  environment {
    variables = {
      CALLBACK_URL    = var.callback_url
      CALLBACK_SECRET = var.callback_secret
    }
  }
}

# S3 이벤트 알림 → trigger-mediaconvert Lambda
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_mediaconvert.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.media_bucket_arn
}

resource "aws_s3_bucket_notification" "media_upload" {
  bucket = var.media_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.trigger_mediaconvert.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ".mp4"
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}

# EventBridge Rule → update-video-status Lambda
resource "aws_cloudwatch_event_rule" "mediaconvert_complete" {
  name = "${var.project_name}-mediaconvert-status"

  event_pattern = jsonencode({
    source      = ["aws.mediaconvert"]
    detail-type = ["MediaConvert Job State Change"]
    detail = {
      status = ["COMPLETE", "ERROR"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.mediaconvert_complete.name
  arn  = aws_lambda_function.update_video_status.arn
}

resource "aws_lambda_permission" "eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_video_status.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.mediaconvert_complete.arn
}
