# Demo Scenarios (Execution Walkthrough)

This document outlines three practical execution scenarios to demonstrate and verify the functionality of the `rebase-backup.sh` script.

---

## Scenario 1: Clean Backup Run (Success Flow)

This scenario demonstrates a successful backup generation process. The script compresses the target directory, saves the archive safely to the destination folder, and logs the milestone milestones to both the console and the persistent log file.

### Execution Command
```bash
./rebase-backup.sh -s ./test_source -d ./test_dest -r 3
```

### Visual Verification
![Successful Backup Run](assets/backup-screenshot.png)

---

## Scenario 2: Retention Policy Enforcement (Cleanup Flow)

This scenario demonstrates how the script dynamically monitors backlogs. When the number of stored archives exceeds your specified retention limit (`-r`), the script flags older iterations and cleanly purges them to prevent disk space exhaustion.

### Execution Command
```bash
./rebase-backup.sh -s ./test_source -d ./test_dest -r 3
```

### Visual Verification
![Retention Cleanup and Logging](assets/removing-screenshot.png)

---

## Scenario 3: Triggered Failure Alert (Webhook Notification Flow)

This scenario demonstrates how the utility alerts administrators when a failure occurs. By targeting a non-existent directory or triggering a compression failure, the script catches the crash, halts execution safely via `set -e`, updates the persistent logs with an `[ERROR]`, and sends a JSON alert payload to your external webhook endpoint.

### Execution Command
```bash
./rebase-backup.sh -s ./NON_EXISTENT_DIR -d ./test_dest -r 3 -w "https://discord.com"
```

### Expected Behavior & Console Output
```text
[2026-08-14 14:00:05] [INFO] Creating backup of ./NON_EXISTENT_DIR to ./test_dest/backup-2026-08-14_14-00-05.tar.gz
tar: ./NON_EXISTENT_DIR: Cannot stat: No such file or directory
tar: Error is not recoverable: exiting now
[2026-08-14 14:00:06] [ERROR] Failed to create backup archive: ./test_dest/backup-2026-08-14_14-00-05.tar.gz
```

*Note: If your webhook is intentionally unreachable or invalid during testing, the script will output a `[WARN] Webhook notification failed to send` line right after the failure notice to verify your non-fatal logging configuration works properly.*
