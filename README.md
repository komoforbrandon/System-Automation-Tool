# Rebase Backup Utility (`rebase-backup.sh`)

An idempotent, automated backup script designed to compress directories, send failure alerts via webhooks, maintain file retention policies, and maintain structured logs. This tool is built to run reliably and unattended via system schedulers like `cron`.

![Successful Backup Execution](assets/backup-screenshot.png)

---

## Features
* **Automated Archiving:** Compresses source directories into timestamped `.tar.gz` files.
* **Persistent Logging:** Writes timestamped logs (`INFO`, `WARN`, `ERROR`) to a configurable log file and stdout.
* **Retention Management:** Automatically purges old backups exceeding a user-defined threshold.
* **Failure Alerts:** Sends a JSON payload to a configured webhook (e.g., Discord, Slack) if the backup archiving process fails.
* **Cron-Safe Execution:** Handles environmental restrictions cleanly and manages missing cleanup files safely.

![Retention Cleanup and Logging](assets/removing-screenshot.png)


---

## Installation & Setup

1. **Clone the repository** from GitHub to your local machine:
   ```bash
   git clone https://github.com/komoforbrandon/System-Automation-Tool.git
   cd System-Automation-Tool
   ```
2. **Grant execution permissions** to the script file:
   ```bash
   chmod +x rebase-backup.sh
   ```
3. **Verify dependencies** are installed on your Linux environment: `bash`, `tar`, `find`, `curl`, and `mktemp`.

---

## Command-Line Interface (Flags)

| Flag | Required / Optional | Argument | Description |
| :--- | :--- | :--- | :--- |
| `-s` | **Required** | `SOURCE` | Absolute or relative path to the directory you want to back up. |
| `-d` | **Required** | `DEST` | Directory where the backup archives will be stored. Created if it doesn't exist. |
| `-r` | Optional | `RETENTION` | Number of recent backups to keep. Must be a positive integer. (Default: `7`). |
| `-w` | Optional | `WEBHOOK` | HTTP/HTTPS URL to POST a JSON failure payload to if the backup fails. |
| `-l` | Optional | `LOG_FILE` | Custom path to the persistent log file. (Default: `/tmp/backup.log`). |
| `-v` | Optional | None | Verbose mode. Duplicates all log file outputs directly to `stderr`. |
| `-h` | Optional | None | Displays the usage instructions and exits successfully. |

---

## Usage Example

### Manual Interactive Run
To back up a local website directory to a storage mount with verbose reporting and a custom log file destination:

```bash
./rebase-backup.sh \
  -s /var/www/my-app \
  -d /mnt/storage/backups \
  -r 14 \
  -w "https://discord.com" \
  -l /var/log/backup-app.log \
  -v
```


## Automated Scheduling with Cron

To run this backup completely unattended, you must use absolute system paths for the script interpreter, the script itself, and the directory flags. This ensures it executes flawlessly without relying on user session environment variables.

### Sample Crontab Entry
To configure this script to execute automatically every single day at **2:00 AM**, open your user crontab editor (`crontab -e`) and add the following single line:

```cron
0 2 * * * /usr/bin/env bash /usr/local/bin/rebase-backup.sh -s /var/www/my-app -d /mnt/storage/backups -r 14 -w "https://discord.com" -l /var/log/backup-app.log
```

*Note: Since the script natively handles internal logging to the file specified by `-l`, you do not need to append standard shell redirectors like `>> /var/log/cron.log 2>&1` unless you want to catch syntax errors outside the script's execution.*
