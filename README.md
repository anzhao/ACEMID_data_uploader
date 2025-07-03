# ACEMID_data_uploader
The bash script for uploading ACEMID data to XNAT.
Before running the script, please make sure you have the corresponding data type turned on.

## Transfer Speed Measurement

The script now includes functionality to measure and report upload and download speeds when transferring data to and from XNAT. This helps in monitoring network performance and diagnosing potential bottlenecks.

### Features

- **Real-time Speed Measurement**: Displays upload and download speeds for each file transfer operation
- **Detailed Logging**: Records transfer metrics in JSON format for later analysis
- **Summary Statistics**: Provides aggregate statistics at the end of all transfers
- **Human-readable Format**: Displays speeds in KB/s or MB/s depending on the transfer rate

### How It Works

The script uses cURL's built-in metrics capabilities (`--write-out` option) to measure:
- Upload speed (bytes per second)
- Download speed (bytes per second)
- Total data transferred (bytes)
- Transfer time (seconds)

### Output

During execution, the script will display:
- Individual transfer speeds for each file
- A summary of all transfers at the end of the script

### Log Files

All transfer metrics are logged to:
- `speed_logs/transfer_speeds.json`: Contains detailed metrics for each transfer
- `speed_logs/transfer_errors.log`: Contains any errors that occurred during transfers

### Requirements

The script requires the following utilities:
- `curl` with write-out support
- `bc` for floating-point calculations
- `awk` for formatting output

### Example Output

```
Transfer to https://xnat-server.example.com/data/projects/PROJECT/subjects/SUBJECT/experiments/SESSION/scans/SCAN/resources/RAW/files:
  - Upload: 1048576 bytes at 2.34 MB/s
  - Download: 0 bytes at 0.00 KB/s

===== XNAT Transfer Speed Summary =====

Upload Statistics:
  - Total data: 25.75 MB
  - Average speed: 2345.67 KB/s (2.29 MB/s)

Download Statistics:
  - Total data: 1.25 MB
  - Average speed: 1234.56 KB/s (1.21 MB/s)

Total transfers: 10
Detailed logs available in: speed_logs/transfer_speeds.json

======================================
```
