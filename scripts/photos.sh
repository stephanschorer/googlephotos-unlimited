#!/bin/bash

# --- Configuration ---
server_user="username"
server_host="hostname.xy"
server_dest_dir="/path/to/dcim/"
phone_dcim_source_dir="$HOME/storage/dcim/Camera/"
phone_screenshot_source_dir="$HOME/storage/pictures/Screenshots/"
phone_backup_dir="$HOME/storage/shared/Trash/"
ssh_key="~/.ssh/id_rsa"
rsync_options=(-avz --exclude '.*')
timestamp_file="$HOME/.last_sync_timestamp"
syncthing_server="https://syncthing_container"
syncthing_api="keykeykeykeykeykey"
device_id="Pixel / Pixel XL Syncthing Device ID"

# --- Functions ---
check_server_connection() {
  ping -c 4 "$server_host" > /dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo -e "✅|Server is reachable."
    check_pixelxl_connection
  else
    echo -e "❌|Check Network Connection!\n"
    exit 1
  fi
}

check_pixelxl_connection() {
  # Get the API response and extract the lastSeen value for the device
  last_seen=$(curl -sX GET -H "X-API-Key: $syncthing_api" $syncthing_server/rest/stats/device | jq -r --arg device_id "$device_id" '.[$device_id].lastSeen')

  # Convert the lastSeen timestamp to epoch seconds
  last_seen_epoch=$(date -d "$last_seen" +%s)

  # Get the current epoch time
  current_epoch=$(date +%s)

  # Calculate the difference in seconds
  time_diff=$((current_epoch - last_seen_epoch))

  # Check if the device was active in the last hour (3600 seconds)
  if ((time_diff <= 3600)); then
    echo -e "✅|Pixel XL was active within the last hour.\n"
  else
    echo -e "❌|Pixel XL was NOT active within the last hour!\n"
  fi
}

sync_images() {
  # Get the last sync timestamp
  last_sync=$(cat "$timestamp_file" 2> /dev/null)

  # Find files deleted on the server
  deleted_files=$(rsync -avzn --delete -e "ssh -i $ssh_key -p 22" "$server_user@$server_host:$server_dest_dir" "$phone_dcim_source_dir" | awk '/deleting/ {print $2}')

  # Check if there are any deleted files
  echo "⌛|Checking for already backed-up Images..."
  if [[ -n "$deleted_files" ]]; then
    # Find files that are deleted on the server
    echo "$deleted_files" | while read -r file; do
      # Only move files older than the last sync
      if [[ -n "$last_sync" ]] && [[ $(stat -c %Y "$phone_dcim_source_dir/$file") -le "$last_sync" ]]; then
        mkdir -p "$phone_backup_dir"
        if mv "$phone_dcim_source_dir/$file" "$phone_backup_dir"; then
          echo " - Trashed: $file"
        else
          echo -e "❌|Error moving $file to $phone_backup_dir!\n"
          exit 1
        fi
      fi
    done
  fi

  # Check if new images are available
  new_images=0
  if [[ -n "$last_sync" ]] && find "$phone_dcim_source_dir" -type f -newermt "@$last_sync" -print -quit | grep -q .; then
    new_images=1
  fi

  if [ $new_images -eq 1 ]; then
    echo "⌛|Uploading Images..."
    # Sync new files to remote server
    rsync "${rsync_options[@]}" -e "ssh -i $ssh_key -p 22" "$phone_dcim_source_dir" "$server_user@$server_host:$server_dest_dir"
    if [[ $? -eq 0 ]]; then
      echo -e "✅|All Images backed-up successfully.\n"
    else
      echo -e "❌|Error syncing Images!\n"
      exit 1
    fi
  else
    echo -e "✅|All Images already backed-up.\n"
  fi
}

sync_screenshots() {
  # Get the last sync timestamp
  last_sync=$(cat "$timestamp_file" 2> /dev/null)

  # Check if new screenshots are available
  new_screenshots=0
  if [[ -n "$last_sync" ]] && find "$phone_screenshot_source_dir" -type f -newermt "@$last_sync" -print -quit | grep -q .; then
    new_screenshots=1
  fi

  if [ $new_screenshots -eq 1 ]; then
    # Build the rsync exclude list based on the last sync timestamp
    echo "⌛|Building Exclusion List..."
    exclude_list=()
    if [[ -n "$last_sync" ]]; then
      while IFS= read -r -d '' file; do 
        filename=$(basename "$file")  # Extract filename
        exclude_list+=("--exclude" "$filename")
      done < <(find "$phone_screenshot_source_dir" -type f ! -newermt "@$last_sync" -print0)
    fi

    echo "⌛|Uploading Screenshots..."
    # Sync new files to remote server, excluding files newer than last sync
    rsync "${rsync_options[@]}" "${exclude_list[@]}" -e "ssh -i $ssh_key -p 22" "$phone_screenshot_source_dir" "$server_user@$server_host:$server_dest_dir"
    if [[ $? -eq 0 ]]; then
      echo -e "✅|All Screenshots backed-up successfully.\n"
    else
      echo -e "❌|Error syncing Screenshots!\n"
      exit 1
    fi
  else
    echo -e "✅|All Screenshots already backed-up.\n"
  fi
}

# --- Main Script ---

termux-wake-lock

echo "⚓|Testing Server Reachability - Please stand by..."
check_server_connection

echo "⚓|Photos Backup in Progress - Please stand by..."
sync_images

echo "⚓|Screenshots Backup in Progress - Please stand by..."
sync_screenshots

# Save current timestamp for next iteration
date +%s > "$timestamp_file"

read -p "✅|Done Press Enter to Exit..."
termux-wake-unlock
