locals {
  # SNS notification count - only create if SNS topic is provided
  sns_notification_count = var.sns_topic_arn != "" ? 1 : 0
}
