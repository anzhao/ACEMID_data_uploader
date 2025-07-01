# ACEMID_data_uploader

A secure collection of scripts for uploading ACEMID and dermoscopy data to XNAT.

## Security Improvements

This repository has been updated with several security improvements:

1. **Secure Credential Management**
   - Credentials are now stored in a separate `.env` file
   - Template provided in `config/.env.template`
   - Proper file permissions enforced

2. **Input Validation**
   - All user inputs are validated and sanitized
   - Path traversal prevention
   - Command injection prevention

3. **Secure Network Communication**
   - HTTPS enforcement for all API calls
   - Certificate validation
   - Connection timeouts

4. **PHI Protection**
   - Enhanced PHI redaction patterns
   - Secure temporary file handling
   - PHI access logging

5. **Secure File Operations**
   - Path validation
   - Symbolic link checking
   - Secure temporary file creation

6. **Comprehensive Logging**
   - Security event logging
   - Error handling
   - Audit trails

7. **Docker Security**
   - Non-root user in container
   - Minimal dependencies
   - Secure environment variable handling

## Setup Instructions

### Configuration

1. Copy the template configuration file:
   ```bash
   cp config/.env.template config/.env
   ```

2. Edit the configuration file with your XNAT credentials:
   ```bash
   nano config/.env
   ```

3. Set secure permissions on the configuration file:
   ```bash
   chmod 600 config/.env
   ```

### Running Scripts

Before running the scripts, make sure you have the corresponding data type turned on in XNAT.

#### ACEMID Data Upload

```bash
./ACEMID_data_uploader.sh
```

#### Dermoscopy Data Upload

```bash
./dermoscopy_data_upload input.csv
```

#### PHI Redaction

```bash
./remove_phi_report.sh input_report.pdf output_redacted.pdf
```

#### Lesion and Dexi Data Collection

```bash
./lesion_dexi_data.sh output_directory
```

#### Stage Server Monitoring

```bash
./stage_server_monitor.sh /path/to/watch/directory
```

## Docker Usage

Build the Docker image:

```bash
docker build -t acemid-uploader .
```

Run the container with your configuration:

```bash
docker run -v $(pwd)/config/.env:/app/config/.env -v $(pwd)/data:/app/data acemid-uploader
```

## Security Best Practices

1. **Never commit credentials** to version control
2. Always use **HTTPS** for XNAT communication
3. Keep the scripts and dependencies **updated**
4. Use **strong passwords** for XNAT accounts
5. Follow the **principle of least privilege** when setting up XNAT accounts
6. **Regularly audit** access logs
7. **Securely delete** temporary files containing PHI

## License

This project is licensed under the MIT License - see the LICENSE file for details.
