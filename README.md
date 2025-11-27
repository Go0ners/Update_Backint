# AWS Backint Agent Updater

Automatic update script for AWS Backint Agent for SAP HANA.

## Usage

```bash
sudo ./Update_Backint.sh
```

## Features

- Automatic detection of existing binary permissions and ownership
- Safe update process with error handling
- Version verification after update
- Minimal dependencies (wget, tar, stat)

## Requirements

- Root privileges
- Existing AWS Backint Agent installation in `/hana/shared/aws-backint-agent`
- Internet connectivity to download from S3

## Author

Maxime GIQUEL