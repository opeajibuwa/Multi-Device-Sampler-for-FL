#!/bin/bash

# Define ANSI escape codes
yellow='\e[93m'  # Yellow text color
reset='\e[0m'    # Reset formatting

########---------------------------CPU----------------------------------------#######

# Extract CPU Type
cpu_type=$(cat /proc/cpuinfo | grep "model name" | head -1 | cut -d: -f2-)

# Extract System Model
system_model=$(cat /proc/cpuinfo | grep "model" | head -1 | cut -d: -f2-)

# Extract Processor's Architecture
processor_architecture=$(cat /proc/cpuinfo | grep "cpu family" | head -1 | cut -d: -f2-)

# Extract Base Speed (Ghz)
base_speed=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | cut -d: -f2-)
base_speed_ghz=$(echo "scale=2; $base_speed / 1000" | bc)

# Extract Number of Processors
number_of_processors=$(cat /proc/cpuinfo | grep "physical id" | uniq -c | wc -l)

# Extract Number of Cores
number_of_cores=$(cat /proc/cpuinfo | grep "cpu cores" | uniq -c | wc -l)

# Extract Logical Processors
logical_processors=$(cat /proc/cpuinfo | grep "processor" | wc -l)

# Extract Virtualization
virtualization=$(cat /proc/cpuinfo | grep "vmx" | wc -l)
if [ $virtualization -gt 0 ]; then
  virtualization="Yes"
else
  virtualization="No"
fi


# Extract cache information
cache_info=$(lscpu | grep -E "L[123] cache" | awk -F': *' '{print $1 " : " $2}')
cache_info_l1d=$(lscpu | grep -E "L1d cache" | awk -F': *' '{print $1 " : " $2}')
cache_info_l1i=$(lscpu | grep -E "L1i cache" | awk -F': *' '{print $1 " : " $2}')

# Assign each line to a separate variable
l1d_cache=$(echo "$cache_info_l1d" | grep "L1d cache")
l1i_cache=$(echo "$cache_info_l1i" | grep "L1i cache")
l2_cache=$(echo "$cache_info" | grep "L2 cache")
l3_cache=$(echo "$cache_info" | grep "L3 cache")


# Get the current CPU utilization
cpu_utilization=$(top -bn1 | grep "%Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)

# Get the current number of processes
processes=$(ps -e | wc -l)

# Get the current number of threads
threads=$(ps -eLf | wc -l)

# Get the system uptime
system_uptime=$(uptime -p)

# Print Static CPU Information to Screen
# echo -e "${yellow}Static CPU Information:${reset}"
echo -e "Static CPU Information:"
echo "-------------------"

printf "CPU Type: %s\n" "$cpu_type"
printf "System Model: %s\n" "$system_model"
printf "Processor's Architecture: %s\n" "$processor_architecture"
printf "Base Speed (Ghz): %0.1f\n" "$base_speed_ghz"
printf "Number of Processors: %d\n" "$number_of_processors"
printf "Number of Cores: %d\n" "$number_of_cores"
printf "Logical Processors: %d\n" "$logical_processors"
printf "Virtualization: %s\n" "$virtualization"
printf "%s\n" "$l1d_cache"
printf "%s\n" "$l1i_cache"
printf "%s\n" "$l2_cache"
printf "%s\n" "$l3_cache"


# Print Semi-Static Memory Information to Screen
echo ""
# echo -e "${yellow}Dynamic CPU Information:${reset}"
echo -e "Dynamic CPU Information:"
echo "-------------------"

# Print the CPU information
printf "Current CPU Utilization (%%): %s\n" "$cpu_utilization"
printf "Current Number of Processes: $processes\n"
printf "Current Number of Threads: $threads\n"

echo ""
# printf "${yellow}System Uptime: $system_uptime${reset}\n"
printf "System Uptime: $system_uptime\n"

######---------------------------------RAM------------------------------------########

# Function to convert bytes to human-readable size
human_readable_size() {
    local size=$1
    local units=('B' 'KB' 'MB' 'GB' 'TB')
    local unit=0
    while ((size > 1024)); do
        size=$(($size / 1024))
        unit=$(($unit + 1))
    done
    echo "$size ${units[$unit]}"
}

# Get memory information
total_physical_memory=$(free -h | awk '/^Mem:/ {print $2}')
available_physical_memory=$(free -h | awk '/^Mem:/ {print $7}')
total_virtual_memory=$(free -h | awk '/^Swap:/ {print $2}')
available_virtual_memory=$(free -h | awk '/^Swap:/ {print $4}')
committed_memory=$(free -h | awk '/^Swap:/ {print $3}')

# Get available HDD space
hdd_space_available=$(df -h / | awk 'NR==2 {print $4}')

# Function to convert bytes to human-readable size
human_readable_size() {
    local size=$1
    local units=('B' 'KB' 'MB' 'GB' 'TB')
    local unit=0
    while ((size > 1024)); do
        size=$(($size / 1024))
        unit=$(($unit + 1))
    done
    echo "$size ${units[$unit]}"
}

# Get dynamic memory information
used_memory=$(free -h | awk '/^Mem:/ {print $3}')

paged_pool_memory=$(vmstat -s | grep "paged in" | awk '{print $1}')

# Convert paged pool memory to human-readable size
paged_pool_memory_human=$(human_readable_size $paged_pool_memory)

# Print Semi-Static Memory Information to Screen
echo ""
# echo -e "${yellow}Semi-Static Memory Information:${reset}"
echo -e "Semi-Static Memory Information:"
echo "-------------------"

printf "Total Physical Memory (RAM): %s\n" "$total_physical_memory"
printf "Available Physical Memory (RAM): %s\n" "$available_physical_memory"
printf "Total Virtual Memory (Commit size): %s\n" "$total_virtual_memory"
printf "Available Virtual Memory: %s\n" "$available_virtual_memory"
printf "Committed Memory (Virtual Memory Used): %s\n" "$committed_memory"
printf "HDD Space Available: %s\n" "$hdd_space_available"

# Print Dynamic Memory Information to Screen
echo ""
# echo -e "${yellow}Dynamic Memory Information:${reset}"
echo -e "Dynamic Memory Information:"
echo "-------------------"

printf "Used Memory (RAM): %s\n" "$used_memory"
printf "Paged Pool Memory: %s\n" "$paged_pool_memory_human"
printf "\n"

# Print list of top 10 running processes by memory utilization
process_list=$(ps aux --sort=-%mem | head -n 11)
# echo -e "${yellow}List of Top 10 Processes by Memory Utilization:${reset}"
echo -e "List of Top 10 Processes by Memory Utilization:"
echo "---------------------------------------------"
echo "$process_list" | awk 'NR>1 {
    mem = $4;
    cmd = $11;
    pid = $2;
    printf "Process: %s | ProcessID: %s | Memory Utilization: %s%%\n", cmd, pid, mem
}'

######---------------------------------GPU------------------------------------########

# Function to get the value associated with a key in nvidia-smi output
get_nvidia_smi_value() {
    local key="$1"
    nvidia-smi --query-gpu="$key" --format=csv,noheader,nounits
}

# Check if NVIDIA GPU is present
if lspci -nnk | grep -i -E 'vga|3d controller' &> /dev/null; then
    # Get GPU information if a GPU is present
    gpu_name=$(get_nvidia_smi_value "name")
    driver_version=$(get_nvidia_smi_value "driver_version")
    temperature=$(get_nvidia_smi_value "temperature.gpu")
    utilization_gpu=$(get_nvidia_smi_value "utilization.gpu")
    utilization_memory=$(get_nvidia_smi_value "utilization.memory")
    memory_total=$(get_nvidia_smi_value "memory.total")
    memory_free=$(get_nvidia_smi_value "memory.free")
    memory_used=$(get_nvidia_smi_value "memory.used")
    fan_speed=$(get_nvidia_smi_value "fan.speed")
    power_management=$(get_nvidia_smi_value "power.management")
    power_limit=$(get_nvidia_smi_value "power.limit")
    average_power_drawn=$(get_nvidia_smi_value "power.draw")



# Print GPU Memory Information
echo ""
# echo -e "${yellow}GPU Memory Information:${reset}"
echo -e "GPU Memory Information:"
echo "-------------------"

printf "GPU Name: %s\n" "$gpu_name"
    printf "Driver Version: %s\n" "$driver_version"
    printf "Temperature (°C): %s\n" "$temperature"
    printf "Utilization GPU: %s%%\n" "$utilization_gpu"
    printf "Utilization Memory: %s%%\n" "$utilization_memory"
    printf "Memory Total: %s\n" "$memory_total"
    printf "Memory Free: %s\n" "$memory_free"
    printf "Memory Used: %s\n" "$memory_used"
    printf "Fan Speed: %s%%\n" "$fan_speed"
    printf "Power Management: %s\n" "$power_management"
    printf "Power Limit: %s W\n" "$power_limit"
    printf "Average Power Drawn: %s W\n" "$average_power_drawn"
else
    # Print a message if no NVIDIA GPU is found
    printf "System has no NVIDIA GPU." 
fi


######---------------------------------NETWORK CONN------------------------------------########

# Get network interface information
interface_name=$(ip -o -4 route show to default | awk '{print $5}')
device_type=$(cat /sys/class/net/$interface_name/device/modalias)
connection_type="Wired"

# Get IPv4 and IPv6 addresses
ipv4_address=$(ip -4 addr show dev $interface_name | awk '$1 == "inet" { print $2 }')
ipv6_address=$(ip -6 addr show dev $interface_name | awk '$1 == "inet6" { print $2 }')

# Calculate average throughput in MB/s
rx_bytes_start=$(cat "/sys/class/net/$interface_name/statistics/rx_bytes")
tx_bytes_start=$(cat "/sys/class/net/$interface_name/statistics/tx_bytes")
sleep 1
rx_bytes_end=$(cat "/sys/class/net/$interface_name/statistics/rx_bytes")
tx_bytes_end=$(cat "/sys/class/net/$interface_name/statistics/tx_bytes")
average_throughput=$((($rx_bytes_end + $tx_bytes_end - $rx_bytes_start - $tx_bytes_start) / 1024 / 1024))  # In MB/s

# Print Network Interface Information
echo ""
# echo -e "${yellow}Network Interface Information:${reset}"
echo -e "Network Interface Information:"
echo "-------------------"

# Print network interface information
printf "Connection Type: %s\n" "$connection_type"
printf "IPv4 Address: %s\n" "$ipv4_address"
printf "IPv6 Address: %s\n" "$ipv6_address"
printf "Average Throughput: %.2f MB/s\n" "$average_throughput"

# Function to extract and calculate average from an array of values
calculate_average() {
    local values=("$@")
    local sum=0
    for value in "${values[@]}"; do
        sum=$(awk "BEGIN {print $sum + $value}")
    done
    local count=${#values[@]}
    if [ $count -eq 0 ]; then
        echo "N/A"
    else
        echo "scale=2; $sum / $count" | bc
    fi
}

# Run a series of ping tests
ping_results=$(ping -c 10 example.com)  # Change "example.com" to the target domain or IP address

# Extract latency, jitter, and packet loss values
latencies=($(echo "$ping_results" | awk -F'/' 'NR>1 {print $5}'))
jitters=($(echo "$ping_results" | awk -F'/' 'NR>1 {print $6}'))
packet_loss=$(echo "$ping_results" | awk -F'[%, ]' '/packet loss/ {print $9}')

# Calculate average latency and jitter
average_latency=$(calculate_average "${latencies[@]}")
average_jitter=$(calculate_average "${jitters[@]}")

# Print Network Performance Metrics Information
echo ""
# echo -e "${yellow}Network Performance Metrics:${reset}"
echo -e "Network Performance Metrics:"
echo "-------------------"

printf "Average Latency: %s ms\n" "$average_latency"
printf "Jitter: %s ms\n" "$average_jitter"
printf "Packet Loss: %s%%\n" "$packet_loss"

######------------------------------------OS Info---------------------------------------######

# Get OS Name and OS Version
os_name=$(lsb_release -d | awk -F"\t" '{print $2}')
os_version=$(lsb_release -r | awk -F"\t" '{print $2}')

# Get OS Local Time
os_local_time=$(date)

# Get OS Last Boot Uptime
last_boot_epoch=$(awk '{print $1}' /proc/uptime)
os_last_boot_uptime=$(date -d "now - $last_boot_epoch seconds" "+%Y-%m-%d %H:%M:%S")

# Get OS Uptime
os_uptime=$(uptime -p)

# Get OS Build Type
os_build_type=$(uname -o)

# Get Foreground Application Boost
foreground_app_boost=$(cat /proc/sys/vm/dirty_writeback_centisecs)

# Get Number of Users
number_of_users=$(who | wc -l)

# Get OS Architecture
os_architecture=$(uname -m)

# Get OS Language
os_language=$(locale | grep "LANG=" | awk -F'=' '{print $2}')

# Get Timezone
timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')

# Print Operating Systems Information
echo ""
# echo -e "${yellow}Operating System (OS) Info:${reset}"
echo -e "Operating System (OS) Info:"
echo "-------------------"

printf "OS Name: %s\n" "$os_name"
printf "OS Version: %s\n" "$os_version"
printf "OS Local Time: %s\n" "$os_local_time"
printf "OS Last Boot Uptime: %s\n" "$os_last_boot_uptime"
printf "OS Uptime: %s\n" "$os_uptime"
printf "OS Build Type: %s\n" "$os_build_type"
printf "Foreground Application Boost: %s\n" "$foreground_app_boost"
printf "Number of Users: %d\n" "$number_of_users"
printf "OS Architecture: %s\n" "$os_architecture"
printf "OS Language: %s\n" "$os_language"
printf "Timezone: %s\n" "$timezone"


######-------------------------------Power/Battery Info------------------------------------######

# Print Battery/Power Information
echo ""
# echo -e "${yellow}Battery/Power Info:${reset}"
echo -e "Battery/Power Info:"
echo "-------------------"

# Check if it's a laptop
if [ -e "/sys/class/power_supply/BAT0" ]; then
    # Get Battery Level
    battery_level=$(cat /sys/class/power_supply/BAT0/capacity)

    # Check if it's currently charging
    if [ "$(cat /sys/class/power_supply/BAT0/status)" = "Charging" ]; then
        charging="Yes"
    else
        charging="No"
    fi

    # Print battery information
    printf "Battery Level: %s%%\n" "$battery_level"
    printf "Charging: %s\n" "$charging"
else
    # It's a desktop computer
    printf "Battery Level: This is a desktop computer"
fi

#---------------------------------------------------------------------------------------------------#
