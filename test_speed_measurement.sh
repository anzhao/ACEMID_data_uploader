#!/bin/bash
# Make the script executable with: chmod +x test_speed_measurement.sh

# Test script for XNAT transfer speed measurement
# This script simulates file transfers to test the speed measurement functionality

# Create test directory and files
mkdir -p test_data
mkdir -p speed_logs

# Create a test file (10MB)
dd if=/dev/urandom of=test_data/test_file_10mb.bin bs=1M count=10 2>/dev/null

echo "===== Testing XNAT Transfer Speed Measurement ====="

# Source the functions from ACEMID_data_uploader.sh
# Extract the measure_transfer_speed function
grep -A 60 "measure_transfer_speed()" /workspace/ACEMID_data_uploader.sh > /tmp/measure_function.sh
source /tmp/measure_function.sh

# Test upload speed measurement (simulated with curl to httpbin.org)
echo "Testing upload speed measurement..."
TEMP_OUTPUT=$(mktemp)
measure_transfer_speed "curl -X POST -F \"file=@test_data/test_file_10mb.bin\"" \
    "https://httpbin.org/post" \
    "$TEMP_OUTPUT"
rm -f "$TEMP_OUTPUT"

# Test download speed measurement
echo "Testing download speed measurement..."
TEMP_OUTPUT=$(mktemp)
measure_transfer_speed "curl -X GET" \
    "https://httpbin.org/bytes/1048576" \
    "$TEMP_OUTPUT"
rm -f "$TEMP_OUTPUT"

# Extract and source the summary function
grep -A 100 "display_transfer_summary()" /workspace/ACEMID_data_uploader.sh > /tmp/summary_function.sh
source /tmp/summary_function.sh

# Display summary
display_transfer_summary

# Clean up
echo "Cleaning up test files..."
rm -rf test_data

echo "===== Test Complete ====="