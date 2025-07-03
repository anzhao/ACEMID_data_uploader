#!/bin/bash

# Make scripts executable
chmod +x /workspace/ACEMID_data_uploader.sh
chmod +x /workspace/test_speed_measurement.sh
chmod +x /workspace/fix_issue.sh

echo "Scripts are now executable."
echo "To test the speed measurement functionality, run:"
echo "./test_speed_measurement.sh"
echo
echo "To use the main script with speed measurement:"
echo "./ACEMID_data_uploader.sh"