#!/bin/bash

# Ensure the serial device does not hang up
stty -F /dev/ttyUSB0 -hupcl

# Send initial message
echo "Hello/Test" > /dev/ttyUSB0
sleep 5

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

# Function to control LCD on/off based on the time
control_lcd_based_on_time() {
  current_hour=$(date +"%H")

  # If time is between 22:00 (10 PM) and 08:00 (8 AM)
  if [ "$current_hour" -ge 22 ] || [ "$current_hour" -lt 8 ]; then
    echo "lcdoff" > /dev/ttyUSB0  # Send LCD off command
  else
    echo "lcdon" > /dev/ttyUSB0   # Send LCD on command
  fi

  sleep 10  # Sleep for 10 seconds before returning
}

# Function to print uptime
print_uptime() {
  row1="Uptime"
  row2=$(uptime -p | sed 's/up\s*//g' | sed 's/\s*week/w/g' | sed 's/\s*days/d/g' | sed 's/\s*day/d/g' | sed 's/\s*hours/h/g' | sed 's/\s*minutes/m/g' | sed 's/,//g')
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print disk usage
print_disk_usage() {
  row1="Disk use"
  row2=$(screenfetch | grep Disk | cut -f2 -d: | cut -c 6-)
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print load averages
print_load_averages() {
  row1="Load average"
  row2=$(uptime | grep -oP '(?<=load average: ).*' | sed 's/,//g')
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print CPU temperature
print_cpu_temperature() {
  row1="CPU Temp"
  row2=$(sensors | grep id | cut -f2 -d: | cut -f1 -d"(" | sed 's/\s*°//g' | cut -c 3-)
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print memory usage
print_memory_usage() {
  row1="Mem Usage"
  row2=$(free -h | grep Mem | awk '{print $3 "/" $2}')
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print swap usage
print_swap_usage() {
  row1="Swap Usage"
  row2=$(free -h | grep Swap | awk '{print $3 "/" $2}')
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print top process by CPU usage
print_top_process_cpu() {
  row1="Top Proc"
  row2=$(ps -eo %cpu,%mem,comm --sort=-%cpu | head -n 2 | tail -n 1 | awk '{print $3 ":" $1"%"}')
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print top memory-consuming process
print_top_process_memory() {
  row1="Top Mem Proc"
  row2=$(ps -eo %mem,comm --sort=-%mem | head -n 2 | tail -n 1 | awk '{print $2 ":" $1"%"}')
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print network IP address
print_ip_address() {
  row1="IP Address"
  row2=$(ip -4 addr show enp0s25 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print logged-in users
print_logged_in_users() {
  row1="Users"
  row2=$(who | wc -l)
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print current system time
print_system_time() {
  row1="Time"
  row2=$(date +"%H:%M:%S")
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print Ethernet speeds (Download/Upload)
print_eth_speed() {
  iface="eno1"
  prev_rx_bytes=$(grep $iface /proc/net/dev | awk '{print $2}')
  prev_tx_bytes=$(grep $iface /proc/net/dev | awk '{print $10}')

  sleep 1

  current_rx_bytes=$(grep $iface /proc/net/dev | awk '{print $2}')
  current_tx_bytes=$(grep $iface /proc/net/dev | awk '{print $10}')

  rx_diff=$((current_rx_bytes - prev_rx_bytes))
  tx_diff=$((current_tx_bytes - prev_tx_bytes))

  rx_speed=$(convert_to_human_readable $rx_diff)
  tx_speed=$(convert_to_human_readable $tx_diff)

  row1="Download"
  row2="$rx_speed"
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10

  row1="Upload"
  row2="$tx_speed"
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print security updates
print_security_updates() {
  row1="Security Updates"
  row2=$(apt-get --just-print upgrade | grep -P '^\d+ upgraded' | cut -d" " -f1)
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print total disk read/write speeds
print_disk_io() {
  get_disk_io() {
    read_speed=$(iostat -d 1 2 | grep -E -v 'loop|ram' | tail -n +5 | awk '{sum+=$3} END {print sum}')
    write_speed=$(iostat -d 1 2 | grep -E -v 'loop|ram' | tail -n +5 | awk '{sum+=$4} END {print sum}')
    echo "$read_speed $write_speed"
  }

  io_stats=$(get_disk_io)
  read_speed=$(echo $io_stats | awk '{print $1}')
  write_speed=$(echo $io_stats | awk '{print $2}')

  if (( $(echo "$read_speed >= 1024" | bc -l) )); then
    read_speed=$(echo "scale=2; $read_speed/1024" | bc)
    read_unit="MB/s"
  else
    read_unit="KB/s"
  fi

  if (( $(echo "$write_speed >= 1024" | bc -l) )); then
    write_speed=$(echo "scale=2; $write_speed/1024" | bc)
    write_unit="MB/s"
  else
    write_unit="KB/s"
  fi

  row1="Total Disk Read"
  row2=$(printf "%.2f %s" "$read_speed" "$read_unit")
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10

  row1="Total Disk Write"
  row2=$(printf "%.2f %s" "$write_speed" "$write_unit")
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print number of running processes
print_process_count() {
  row1="Processes"
  row2=$(ps -e | wc -l)
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print number of open file descriptors
print_open_files() {
  row1="Open Files"
  row2=$(cat /proc/sys/fs/file-nr | awk '{print $1}')
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Function to print last login username and date
print_last_login() {
  last_info=$(last -n 1 -R | head -n 1)
  username=$(echo "$last_info" | awk '{print $1}')
  last_login=$(echo "$last_info" | awk '{print $4, $5, $6}')
  formatted_date=$(date -d "$last_login" +"%d.%m.")

  row1="Last Login"
  row2="$username $formatted_date"
  echo "$row1/$row2" > /dev/ttyUSB0
  sleep 10
}

# Main loop
while true; do
  control_lcd_based_on_time   # Control LCD on/off based on time
  print_uptime                # Print uptime
  print_disk_usage           # Print disk usage
  print_load_averages        # Print load averages
  print_cpu_temperature      # Print CPU temperature
  print_memory_usage         # Print memory usage
  print_swap_usage           # Print swap usage
  print_top_process_cpu      # Print top process by CPU usage
  print_top_process_memory   # Print top memory-consuming process
  print_ip_address           # Print network IP address
  print_logged_in_users      # Print logged-in users
  print_system_time          # Print current system time
  print_eth_speed            # Print Ethernet speeds (Download/Upload)
  print_security_updates     # Print security updates
  print_disk_io              # Print total disk read/write speeds
  print_process_count        # Print number of running processes
  print_open_files           # Print number of open file descriptors
  print_last_login           # Print last login username and date
done