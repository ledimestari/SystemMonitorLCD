#!/bin/bash

# Define the serial device
serial_device="/dev/ttyUSB0"

# Define time ranges for LCD and LED control
lcd_off_start=22
lcd_off_end=8
led_off_start=23
led_off_end=8

# Ensure the serial device does not hang up
stty -F $serial_device -hupcl

# Send initial message
echo "Hello/Test" > $serial_device
sleep 5

# Initialize variables for network speed calculations
prev_rx_bytes=0
prev_tx_bytes=0

# Function to convert bytes to human-readable format (KB/s, MB/s)
convert_to_human_readable() {
  bytes=$1
  if [ $bytes -lt 1024 ]; then
    echo "${bytes}B/s"
  elif [ $bytes -lt 1048576 ]; then
    echo "$(bc <<< "scale=2; $bytes/1024")KB/s"
  else
    echo "$(bc <<< "scale=2; $bytes/1048576")MB/s"
  fi
}

# Function to get disk read/write speeds
get_disk_io() {
  # Extract read and write speeds for all disks, ignoring lines with 'loop' or 'ram'
  read_speed=$(iostat -d 1 2 | grep -E -v 'loop|ram' | tail -n +5 | awk '{sum+=$3} END {print sum}')
  write_speed=$(iostat -d 1 2 | grep -E -v 'loop|ram' | tail -n +5 | awk '{sum+=$4} END {print sum}')
  # Return values in KB/s
  echo "$read_speed $write_speed"
}

# Function to check current time and turn the LCD on or off
control_lcd_based_on_time() {
  current_hour=$(date +"%H")
  if [ $current_hour -ge $lcd_off_start ] || [ $current_hour -lt $lcd_off_end ]; then
    echo "lcdoff" > $serial_device
  else
    echo "lcdon" > $serial_device
  fi
  sleep 10
}

# Function to update LED gradient or static based on time and CPU usage
update_led_gradient() {
  current_hour=$(date +"%H")
  if [ $current_hour -ge $led_off_start ] || [ $current_hour -lt $led_off_end ]; then
    echo "led000000000/static" > $serial_device
  else
    #cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    #cpu_usage_int=$(printf "%.0f" "$cpu_usage")
    cpu_usage_int=$(mpstat 1 1 | awk '/^Average:/ { usage=int(100-$NF) } END { print usage }')
    # Ensure the CPU usage is within 0-100
    if [ "$cpu_usage_int" -lt 0 ]; then cpu_usage_int=0; fi
    if [ "$cpu_usage_int" -gt 100 ]; then cpu_usage_int=100; fi
    echo "led${cpu_usage_int}/gradient" > $serial_device
  fi
  #sleep 10
}

# Function to print uptime
print_uptime() {
  row1="Uptime"
  row2=$(uptime -p | sed 's/up\s*//g' | sed 's/\s*weeks/w/g' | sed 's/\s*week/w/g' | sed 's/\s*days/d/g' | sed 's/\s*day/d/g' | sed 's/\s*hours/h/g' | sed 's/\s*hour/h/g' | sed 's/\s*minutes/m/g' | sed 's/\s*minute/m/g' | sed 's/,//g')
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print disk usage
print_disk_usage() {
  row1="Disk use"
  row2=$(screenfetch | grep Disk | cut -f2 -d: | cut -c 6-)
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print load averages
print_load_average() {
  row1="Load average"
  row2=$(uptime | grep -oP '(?<=load average: ).*' | sed 's/,//g')
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print CPU temperature
print_cpu_temp() {
  row1="CPU Temp"
  row2=$(sensors | grep id | cut -f2 -d: | cut -f1 -d"(" | sed 's/\s*°//g' | cut -c 3-)
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print memory usage and percentage
print_memory_usage() {
  mem_info=$(free -b | grep Mem)
  mem_used=$(echo $mem_info | awk '{print $3}')
  mem_total=$(echo $mem_info | awk '{print $2}')
  mem_percentage=$(echo "scale=2; ($mem_used/$mem_total)*100" | bc)
  mem_used_gb=$(echo "scale=2; $mem_used/1024/1024/1024" | bc)
  mem_total_gb=$(echo "scale=2; $mem_total/1024/1024/1024" | bc)
  row1=$(printf "Mem Usage %.0f%%" "$mem_percentage")
  row2=$(printf "%.2fG/%.2fG" "$mem_used_gb" "$mem_total_gb")
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print swap usage
print_swap_usage() {
  row1="Swap Usage"
  row2=$(free -h | grep Swap | awk '{print $3 "/" $2}')
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print the top process by CPU usage
print_top_cpu_process() {
  row1="Top Proc"
  row2=$(ps -eo %cpu,%mem,comm --sort=-%cpu | head -n 2 | tail -n 1 | awk '{print $3 ":" $1"%"}')
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print the top memory-consuming process
print_top_mem_process() {
  row1="Top Mem Proc"
  row2=$(ps -eo %mem,comm --sort=-%mem | head -n 2 | tail -n 1 | awk '{print $2 ":" $1"%"}')
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print the IP address
print_ip_address() {
  row1="IP Address"
  row2=$(ip -4 addr show enp0s25 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print number of logged-in users
print_logged_in_users() {
  row1="Users"
  row2=$(who | wc -l)
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print the current system time
print_system_time() {
  row1="Time"
  row2=$(date +"%H:%M:%S")
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print network speeds
print_network_speeds() {
  iface="eno1"
  prev_rx_bytes=$(grep $iface /proc/net/dev | awk '{print $2}')
  prev_tx_bytes=$(grep $iface /proc/net/dev | awk '{print $10}')

  sleep 1

  current_rx_bytes=$(grep $iface /proc/net/dev | awk '{print $2}')
  current_tx_bytes=$(grep $iface /proc/net/dev | awk '{print $10}')

  # Calculate the difference in bytes since the last check
  rx_diff=$((current_rx_bytes - prev_rx_bytes))
  tx_diff=$((current_tx_bytes - prev_tx_bytes))

  # Convert the differences to human-readable format
  rx_speed=$(convert_to_human_readable $rx_diff)
  tx_speed=$(convert_to_human_readable $tx_diff)

  # Print download speed
  row1="Download"
  row2="$rx_speed"
  echo "$row1/$row2" > $serial_device
  sleep 10

  # Print upload speed
  row1="Upload"
  row2="$tx_speed"
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print security updates
print_security_updates() {
  row1="Security Updates"
  row2=$(apt-get --just-print upgrade | grep -P '^\d+ upgraded' | cut -d" " -f1)
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print total disk I/O speeds
print_disk_io_speeds() {
  io_stats=$(get_disk_io)
  read_speed=$(echo $io_stats | awk '{print $1}')
  write_speed=$(echo $io_stats | awk '{print $2}')

  # Format read speed (switch between KB/s and MB/s)
  if (( $(echo "$read_speed >= 1024" | bc -l) )); then
    read_speed=$(echo "scale=2; $read_speed/1024" | bc)
    read_unit="MB/s"
  else
    read_unit="KB/s"
  fi

  # Format write speed (switch between KB/s and MB/s)
  if (( $(echo "$write_speed >= 1024" | bc -l) )); then
    write_speed=$(echo "scale=2; $write_speed/1024" | bc)
    write_unit="MB/s"
  else
    write_unit="KB/s"
  fi

  # Print the total disk read speed
  row1="Total Disk Read"
  row2=$(printf "%.2f %s" "$read_speed" "$read_unit")
  echo "$row1/$row2" > $serial_device
  sleep 10

  # Print the total disk write speed
  row1="Total Disk Write"
  row2=$(printf "%.2f %s" "$write_speed" "$write_unit")
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print number of running processes
print_process_count() {
  row1="Processes"
  row2=$(ps -e | wc -l)
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print the number of open file descriptors
print_open_files() {
  row1="Open Files"
  row2=$(cat /proc/sys/fs/file-nr | awk '{print $1}')
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Function to print the last login info
print_last_login() {
  last_info=$(last -n 1 -R | head -n 1)
  username=$(echo "$last_info" | awk '{print $1}')
  last_login_time=$(echo "$last_info" | awk '{print $5 " " $6}')
  row1="Last Login"
  row2="$username $last_login_time"
  echo "$row1/$row2" > $serial_device
  sleep 10
}

# Main loop
while true; do
  control_lcd_based_on_time
  update_led_gradient
  print_uptime
  update_led_gradient
  print_disk_usage
  update_led_gradient
  print_load_average
  update_led_gradient
  print_cpu_temp
  update_led_gradient
  print_memory_usage
  update_led_gradient
  print_swap_usage
  update_led_gradient
  print_top_cpu_process
  update_led_gradient
  print_top_mem_process
  update_led_gradient
  print_ip_address
  update_led_gradient
  print_logged_in_users
  update_led_gradient
  print_system_time
  update_led_gradient
  print_network_speeds
  update_led_gradient
  print_security_updates
  update_led_gradient
  print_disk_io_speeds
  update_led_gradient
  print_process_count
  update_led_gradient
  print_open_files
  update_led_gradient
  print_last_login
  update_led_gradient
done
