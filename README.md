# terraform-aws-backup-plans

## Description

A basic set of backup plans that can be consistantly created used across the
SBA organization.

### Features

* Configures the AWS Backup service to run weekly and quarterly
* Weekly backups are retained for 90 days
* Quarterly backups are retained forever
* Out of the box will look for tag key-values of `BackupQuarterly: true` and `BackupWeekly: true` to initiate a backup
* Grants necessary service role permissions

## Usage

### Super Simple

```terraform
module "backup-plans" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 3.0"
}
```

### A bit more customization

```terraform
module "backup-plans" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 3.0"

  # Disable quarterly backups
  quarterly_backup_enabled = false

  # Change the weekly backup tag key-value to `AutoBackups = very-yes` for triggering
  weekly_backup_tag_key   = "AutoBackups"
  weekly_backup_tag_value = "very-yes"
}
```

### Cross-region

To enable cross region copies of backup plans, you must set the `cross_region_backup_enabled` variable to true and optionally set the destination region (defaults to us-west-2)

```
module "backup-plans" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 3.0"

  cross_region_backup_enabled = true
  cross_region_destination = "us-west-2"
}
```

## Contributing

We welcome contributions.
To contribute please read our [CONTRIBUTING](CONTRIBUTING.md) document.

All contributions are subject to the license and in no way imply compensation for contributions.

## Code of Conduct

We strive for a welcoming and inclusive environment for all SBA projects.

Please follow this guidelines in all interactions:

* Be Respectful: use welcoming and inclusive language.
* Assume best intentions: seek to understand other's opinions.

## Security Policy

Please do not submit an issue on GitHub for a security vulnerability.
Instead, contact the development team through [HQVulnerabilityManagement](mailto:HQVulnerabilityManagement@sba.gov).
Be sure to include **all** pertinent information.

The agency reserves the right to change this policy at any time.
