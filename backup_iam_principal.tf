data "aws_iam_policy_document" "service_link" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "service_role" {
  count              = local.enabled_count
  name               = "backup-service-role"
  assume_role_policy = data.aws_iam_policy_document.service_link.json
}

resource "aws_iam_role_policy_attachment" "service_role_attachment" {
  count      = local.enabled_count
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = var.enabled ? aws_iam_role.service_role[0].name : ""
}

resource "aws_iam_role_policy_attachment" "s3_service_role_attachment" {
  count      = local.enabled_count
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
  role       = var.enabled ? aws_iam_role.service_role[0].name : ""
}
