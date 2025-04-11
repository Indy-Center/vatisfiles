#!/bin/bash

# Function for logging without affecting the result
log() {
  echo "$@"
}

# Main function that processes files and returns result
update_serials() {
  local changes_made=false
  local files=$(git diff --name-only HEAD^ HEAD | grep '\.json$')
  
  for file in $files; do
    # Check if file has updateSerial field
    if jq -e 'has("updateSerial")' "$file" > /dev/null 2>&1; then
      log "Processing $file..."
      
      # Get current serial
      local current_serial=$(jq '.updateSerial' "$file")
      
      # Get current date in YYYYMMDD format
      local current_date=$(date +"%Y%m%d")
      
      # Extract date and sequence parts
      local date_part=${current_serial:0:8}
      local seq_part=${current_serial:8}
      
      # Determine new serial based on logic
      local new_serial
      if [ "$date_part" = "$current_date" ]; then
        # Same date, increment sequence
        local new_seq=$((10#$seq_part + 1))
        local new_seq=$(printf "%02d" $new_seq)
        new_serial="${current_date}${new_seq}"
      elif [ "$date_part" -gt "$current_date" ]; then
        # Future date, just increment sequence
        local new_seq=$((10#$seq_part + 1))
        local new_seq=$(printf "%02d" $new_seq)
        new_serial="${date_part}${new_seq}"
      else
        # New date, reset sequence
        new_serial="${current_date}00"
      fi
      
      log "Updating serial from $current_serial to $new_serial in $file"
      
      # Update file with new serial
      jq --arg serial "$new_serial" '.updateSerial = ($serial | tonumber)' "$file" > temp.json
      mv temp.json "$file"
      
      # Stage the file
      git add "$file"
      changes_made=true
    fi
  done
  
  # Return result
  echo $changes_made
}

# Run the function and capture only its last line
RESULT=$(update_serials | tail -n 1)

# Display the result for GitHub Actions
echo $RESULT 