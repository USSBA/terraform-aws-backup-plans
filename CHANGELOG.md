# Releases

# v5.0.0

- The module user now has full control over the opt-in settings as the options can vary by region.
- Please use the `aws backup describe-region-settings` to get the list of preferences by region.
- [BREAKING] When upgrading from prior versions to 5.0 the `opt_in_settings` variable must be provided to the module.

# v4.0.2

- Added two new variables with defaulting values:
  - `start_window` -> Amount of time (in minutes) before starting a backup job
  - `completion_window` -> Amount of time (in minutes) a job can run before it is canceled

## v4.0.1

- Added missing s3 permissions necessary for the aws backup service.

## v4.0.0

- ** BREAKING CHANGES **
  - Bumped AWS provider version to `>=4.0, < 5.0`

## v3.4.1
* Adding backup support for the following resources: DocumentDB, Neptune, S3 and VirtualMachine

## v3.4.0
* Bump to support terraform v1.0

## v3.3.0
* Adding daily backup vault and configuration settings

## v3.2.0

* Adding in region config for backup services with `aws_backup_region_settings`
* Adding in feature to allow cross-region backup copies
* Add tagging to tagable resources

## v3.1.0

* Support for Terraform versions 0.13 and above to (but not including) 1.0

## v3.0.0

* Terraform 0.13 Upgrade

## v2.0.0

* Breaking Change: Adding "enabled" check to all resources, which changes the state name and will require delete/replace or manually adjusting the the terraform state

## v1.0.1

* BugFix: cron

## v1.0.0

* Initial Release
