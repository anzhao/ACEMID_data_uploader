#!/bin/bash

# remove_phi_report.sh - Script for removing PHI from dermx reports
# This script has been updated with security improvements

# Load utility scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/input_validation.sh"
source "$SCRIPT_DIR/utils/file_utils.sh"
source "$SCRIPT_DIR/utils/logging.sh"

# Initialize logging
LOG_FILE="${LOG_FILE:-/var/log/phi_redaction.log}"
init_logging "$LOG_FILE"

log_info "Starting PHI redaction process"

# Check if input file is provided
if [ -z "$1" ]; then
  log_error "No input PDF file provided"
  echo "Usage: $0 <input_pdf_file> [output_pdf_file]"
  exit 1
fi

# Input and output dermx report files
INPUT_PDF="$1"
OUTPUT_PDF="${2:-redacted_dermx_report_output.pdf}"

# Validate input file exists
if ! validate_file_exists "$INPUT_PDF" "Input PDF file"; then
  log_error "Input PDF file does not exist: $INPUT_PDF"
  exit 1
fi

# Validate input file is a PDF
if [[ ! "$INPUT_PDF" =~ \.pdf$ ]]; then
  log_error "Input file is not a PDF file: $INPUT_PDF"
  echo "Error: Input file must be a PDF file."
  exit 1
fi

log_info "Processing PDF file: $INPUT_PDF"
log_info "Output will be saved to: $OUTPUT_PDF"

# Create secure temporary files
TEXT_FILE=$(create_secure_temp_file "dermx_report")
REDACTED_TEXT=$(create_secure_temp_file "redacted_report")

# Check if required tools are installed
if ! command -v pdftotext &> /dev/null; then
  log_error "pdftotext is not installed"
  echo "Error: pdftotext is required but not installed. Install it using 'apt-get install poppler-utils'."
  exit 1
fi

if ! command -v enscript &> /dev/null || ! command -v ps2pdf &> /dev/null; then
  log_error "enscript or ps2pdf is not installed"
  echo "Error: enscript and ps2pdf are required but not installed. Install them using 'apt-get install enscript ghostscript'."
  exit 1
fi

# Step 1: Extract text from input dermx report PDF
log_info "Extracting text from PDF"
pdftotext "$INPUT_PDF" "$TEXT_FILE"
if [ $? -ne 0 ]; then
  log_error "Failed to extract text from PDF: $INPUT_PDF"
  echo "Error: Failed to extract text from PDF."
  secure_remove "$TEXT_FILE"
  secure_remove "$REDACTED_TEXT"
  exit 1
fi

# Step 2: Remove PHI from the report
log_info "Redacting PHI from text"
sed -E '
# Redact patient names (First Last format)
s/(report for |patient:? |name:? )([A-Z][a-z]+ [A-Z][a-z]+)/\1[PATIENT NAME]/gi;
# Redact dates (various formats)
s/([0-9]{1,2}\/[0-9]{1,2}\/[0-9]{2,4})/[DATE]/g;
s/([A-Z][a-z]+ [0-9]{1,2}, [0-9]{4})/[DATE]/g;
s/([0-9]{1,2} [A-Z][a-z]+ [0-9]{4})/[DATE]/g;
# Redact phone numbers
s/(\(?[0-9]{3}\)?[-. ]?[0-9]{3}[-. ]?[0-9]{4})/[PHONE]/g;
# Redact email addresses
s/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/[EMAIL]/g;
# Redact SSN
s/([0-9]{3}[-]?[0-9]{2}[-]?[0-9]{4})/[SSN]/g;
# Redact medical record numbers
s/(MRN:? |medical record:? |record #:? )([0-9A-Za-z-]+)/\1[MRN]/gi;
# Redact addresses
s/([0-9]+ [A-Za-z]+ (St|Street|Ave|Avenue|Blvd|Boulevard|Rd|Road|Dr|Drive), [A-Za-z]+, [A-Z]{2} [0-9]{5}(-[0-9]{4})?)/[ADDRESS]/gi;
' "$TEXT_FILE" > "$REDACTED_TEXT"

# Step 3: Convert redacted text back to PDF
log_info "Converting redacted text back to PDF"
enscript "$REDACTED_TEXT" -o - | ps2pdf - "$OUTPUT_PDF"
if [ $? -ne 0 ]; then
  log_error "Failed to convert redacted text to PDF"
  echo "Error: Failed to convert redacted text to PDF."
  secure_remove "$TEXT_FILE"
  secure_remove "$REDACTED_TEXT"
  exit 1
fi

# Step 4: Clean up temporary files
log_debug "Cleaning up temporary files"
secure_remove "$TEXT_FILE"
secure_remove "$REDACTED_TEXT"

log_info "Redacted PDF created: $OUTPUT_PDF"
echo "Redacted PDF created: $OUTPUT_PDF"

# Log the redaction event for audit purposes
log_security "PHI redaction completed for file: $INPUT_PDF, output saved to: $OUTPUT_PDF"
