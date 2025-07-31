# Releases

## v9.0.0
- Must provide a unique `vault_name` input variable and only a 1 vault will be provisioned per module configuration.
- Must provide at least 1 ARN/pattern to the `backup_selection_resoruce_arns` input variable.
- May optionaly provide `backup_selection_conditions` input variable to futher restrict how the ARN match pattern targets resourcs to backup in the vault.
- May optionaly provide `additional_managed_policies` input variable to enhance the base level coverage of resurces by this module (e.g. Redshift may need additional polcies and may require the account to update opt-in settings)

## v8.0.0

- Removed functionality for weekly and monthly backup plans.
- Adjusted daily backup lifecycle policy to 30 days in warm storage and then 90 days in cold storage before being removed.

## v7.0.0

- Module now requires `terraform ~> 1.9`
- We have added necessary roles to the backup policy:
  - AWSBackupServiceRolePolicyForS3Restore
  - AWSBackupServiceRolePolicyForRestores
- Module now can handle restore to s3 and EFS mounts.

## v6.0.0

- Module now requires `terraform ~> 1.5` and `provider ~> 5.0`

## v5.1.0

- A new optional variable `sns_topic_arn` has been added.
- When an `sns_topic_arn` is provided each vault will subscribe and send `modified` and `failure` events.

## v5.0.0

- The module user now has full control over the opt-in settings as the options can vary by region.
- Please use the `aws backup describe-region-settings` to get the list of preferences by region.
- When upgrading from prior versions to 5.0 the `opt_in_settings` variable must be provided to the module.

## v4.0.2

- Added two new variables with defaulting values:
  - `start_window` -> Amount of time (in minutes) before starting a backup job
  - `completion_window` -> Amount of time (in minutes) a job can run before it is canceled

## v4.0.1

- Added missing s3 permissions necessary for the aws backup service.

## v4.0.0

- Bumped AWS provider version to `>=4.0, < 5.0`

## v3.4.1

- Adding backup support for the following resources: DocumentDB, Neptune, S3 and VirtualMachine

## v3.4.0

- Bump to support terraform v1.0

## v3.3.0

- Adding daily backup vault and configuration settings

## v3.2.0

- Adding in region config for backup services with `aws_backup_region_settings`
- Adding in feature to allow cross-region backup copies
- Add tagging to taggable resources

## v3.1.0

- Support for Terraform versions 0.13 and above to (but not including) 1.0

## v3.0.0

- Terraform 0.13 Upgrade

## v2.0.0

- Adding "enabled" check to all resources, which changes the state name and will require delete/replace or manually adjusting the the terraform state

## v1.0.1

- BugFix: cron

## v1.0.0

- Initial Release
