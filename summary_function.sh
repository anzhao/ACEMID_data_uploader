# Function to display summary statistics of all transfers
display_transfer_summary() {
    echo
    echo "===== XNAT Transfer Speed Summary ====="
    echo
    
    if [ -f "speed_logs/transfer_speeds.json" ]; then
        # Calculate average upload and download speeds
        local total_upload_size=0
        local total_download_size=0
        local total_upload_time=0
        local total_download_time=0
        local count=0
        
        while IFS= read -r line; do
            # Extract values from JSON
            local upload_size=$(echo "$line" | grep -o '"size_upload": [0-9.]*' | cut -d' ' -f2)
            local download_size=$(echo "$line" | grep -o '"size_download": [0-9.]*' | cut -d' ' -f2)
            local time_total=$(echo "$line" | grep -o '"time_total": [0-9.]*' | cut -d' ' -f2)
            
            # Add to totals
            total_upload_size=$(echo "$total_upload_size + $upload_size" | bc)
            total_download_size=$(echo "$total_download_size + $download_size" | bc)
            
            # Only count time if there was actual data transfer
            if (( $(echo "$upload_size > 0" | bc -l) )); then
                total_upload_time=$(echo "$total_upload_time + $time_total" | bc)
            fi
            
            if (( $(echo "$download_size > 0" | bc -l) )); then
                total_download_time=$(echo "$total_download_time + $time_total" | bc)
            fi
            
            count=$((count + 1))
        done < speed_logs/transfer_speeds.json
        
        # Calculate average speeds
        if (( $(echo "$total_upload_time > 0" | bc -l) )); then
            local avg_upload_speed=$(echo "scale=2; $total_upload_size / $total_upload_time" | bc)
            local avg_upload_speed_kb=$(echo "scale=2; $avg_upload_speed / 1024" | bc)
            local avg_upload_speed_mb=$(echo "scale=2; $avg_upload_speed_kb / 1024" | bc)
            
            echo "Upload Statistics:"
            echo "  - Total data: $(echo "scale=2; $total_upload_size / (1024*1024)" | bc) MB"
            echo "  - Average speed: $avg_upload_speed_kb KB/s ($avg_upload_speed_mb MB/s)"
        else
            echo "No upload data available."
        fi
        
        if (( $(echo "$total_download_time > 0" | bc -l) )); then
            local avg_download_speed=$(echo "scale=2; $total_download_size / $total_download_time" | bc)
            local avg_download_speed_kb=$(echo "scale=2; $avg_download_speed / 1024" | bc)
            local avg_download_speed_mb=$(echo "scale=2; $avg_download_speed_kb / 1024" | bc)
            
            echo "Download Statistics:"
            echo "  - Total data: $(echo "scale=2; $total_download_size / (1024*1024)" | bc) MB"
            echo "  - Average speed: $avg_download_speed_kb KB/s ($avg_download_speed_mb MB/s)"
        else
            echo "No download data available."
        fi
        
        echo
        echo "Total transfers: $count"
        echo "Detailed logs available in: speed_logs/transfer_speeds.json"
    else
        echo "No transfer data available. Check if any transfers were completed."
    fi
    
    echo
    echo "======================================"
}

# Display summary at the end of all transfers
display_transfer_summary