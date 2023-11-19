######------------------------------------------------Script Begins----------------------------------------------------######
######------------------------------------------------CPU----------------------------------------------------######
# Static Info
$staticInfo = Get-CimInstance Win32_Processor

# Dynamic Info
$dynamicInfo = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor | Where-Object { $_.Name -eq "_Total" }

# System Info
$systemInfo = Get-CimInstance Win32_ComputerSystem

# Retrieve the number of sockets using Get-ComputerInfo
$sockets = (Get-ComputerInfo -Property CsNumberOfProcessors).CsNumberOfProcessors

# Retrieve L1 Cache (KB) from CPU registry (may not be available on all systems)
$l1Cache = (Get-WmiObject Win32_CacheMemory | Select-Object -ExpandProperty MaxCacheSize)[0]

# Retrieve the current total number of running processes
$no_processes = (Get-Process).Count

# Retrieve the total number of threads of all processes
$total_nothreads = (Get-Process | ForEach-Object { $_.Threads.Count } | Measure-Object -Sum).Sum

# Retrieve the system model
$systemModel = $systemInfo.Model  # Add this line to get the system model

# Retrieve the processor architecture
$architecture = (Get-WmiObject -Class Win32_Processor).Architecture

# Retrieve the current CPU Frequency
$MaxClockSpeed = (Get-CimInstance CIM_Processor).MaxClockSpeed
$ProcessorPerformance = (Get-Counter -Counter "\Processor Information(_Total)\% Processor Performance").CounterSamples.CookedValue
$CurrentClockSpeed = $MaxClockSpeed * ($ProcessorPerformance / 100)
$CurrentClockSpeed = $CurrentClockSpeed / 1000
$CurrentClockSpeed = "{0:F2}" -f $CurrentClockSpeed # Format as a string with two decimal places

# Display Static Info
Write-Host "Static CPU Information:" -ForegroundColor Yellow
Write-Host "------------------------"
Write-Host "CPU Type: $($staticInfo.Name)"
Write-Host "System Model: $systemModel"
Write-Host "Processor's Architecture: $architecture"
Write-Host "Base Speed (GHz): $($staticInfo.MaxClockSpeed/1000)"
Write-Host "Number of Processors: $sockets"
Write-Host "Number of Cores: $($staticInfo.NumberOfCores)"
Write-Host "Logical Processors: $($staticInfo.NumberOfLogicalProcessors)"
Write-Host "Virtualization: $($staticInfo.VirtualizationFirmwareEnabled)"
Write-Host "L1 Cache (KB): $l1Cache"
Write-Host "L2 Cache (KB): $($staticInfo.L2CacheSize)"
Write-Host "L3 Cache (KB): $($staticInfo.L3CacheSize)"
Write-Host ""

# Display Dynamic Info
Write-Host "Dynamic CPU Information:" -ForegroundColor Yellow
Write-Host "-------------------------"
Write-Host "Current Utilization (%): $($dynamicInfo.PercentProcessorTime)"
Write-Host "Current Number of Processes: $($no_processes)"
Write-Host "Current Number of Threads: $($total_nothreads)"
Write-Host "Current Processor Speed (GHz): " -ForegroundColor Cyan -NoNewLine
Write-Host $CurrentClockSpeed
Write-Host ""

# System Uptime
$uptime = (Get-ComputerInfo -Property OsUptime).OsUptime
Write-Host "System Uptime: $($uptime)" -ForegroundColor Yellow
Write-Host ""

# Link to retrieve CPU temperature: https://www.delftstack.com/howto/python/python-get-cpu-temperature/

######------------------------------------------------RAM----------------------------------------------------######

# Amount of memory (RAM) in use currently
$memoryInfo = Get-CimInstance Win32_OperatingSystem
$usedMemoryGB = [math]::Round(($memoryInfo.TotalVisibleMemorySize - $memoryInfo.FreePhysicalMemory) / 1MB, 2)

# Total Physical Memory (RAM) in GB
$totalPhysicalMemoryBytes = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory
$totalPhysicalMemoryGB = [math]::Round($totalPhysicalMemoryBytes / 1GB, 2)

# Available Physical Memory (RAM) in GB
$availablePhysicalMemoryMB = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)

# Total Virtual Memory (Commit Size) in GB
$totalVirtualMemoryGB = [math]::Round((Get-CimInstance Win32_OperatingSystem).TotalVirtualMemorySize / 1MB, 2)

# Available Virtual Memory in GB
$availableVirtualMemoryMB = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreeVirtualMemory / 1MB, 2)

# Committed Memory (Virtual Memory Used) in GB
$committedMemoryGB = [math]::Round(((Get-CimInstance Win32_OperatingSystem).TotalVirtualMemorySize - (Get-CimInstance Win32_OperatingSystem).FreeVirtualMemory) / 1MB, 2)

# Amount of HDD space available
$diskInfo = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }  # Filter for local disks
$availableDiskSpaceGB = [math]::Round($diskInfo.FreeSpace[0] / 1GB, 2)

# Display Semi-Static Memory Info
Write-Host "Semi-Static Memory Information:" -ForegroundColor Yellow
Write-Host "------------------------"
Write-Host "Total Physical Memory (RAM): $totalPhysicalMemoryGB GB"
Write-Host "Available Physical Memory (RAM): $availablePhysicalMemoryMB GB"
Write-Host "Total Virtual Memory (Commit Size): $totalVirtualMemoryGB GB"
Write-Host "Available Virtual Memory: $availableVirtualMemoryMB GB"
Write-Host "Committed Memory (Virtual Memory Used): $committedMemoryGB GB"
Write-Host "HDD Space Available: $availableDiskSpaceGB GB"
Write-Host ""

# Display all Dynamic Memory Information
Write-Host "Dynamic Memory Information:" -ForegroundColor Yellow
Write-Host "------------------------"
Write-Host "Used Memory (RAM): $usedMemoryGB GB"
Write-Host ""

# Memory Pools and Non-Paged Pool Memory in MB
$memoryPools = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory | Select-Object -Property PoolNonpagedBytes, PoolPagedBytes
foreach ($pool in $memoryPools) {
    $poolNonpagedMB = [math]::Round($pool.PoolNonpagedBytes / 1MB, 2)
    $poolPagedMB = [math]::Round($pool.PoolPagedBytes / 1MB, 2)
    Write-Host "Non-Paged Pool Memory: $poolNonpagedMB MB | Paged Pool Memory: $poolPagedMB MB" 
}
Write-Host ""

# Memory Usage by Processes - Top 15
$processes = Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 15 -Property ProcessName, WorkingSet, PrivateMemorySize

foreach ($process in $processes) {
    $workingSetMB = [math]::Round($process.WorkingSet / 1MB, 2)
    $privateMemorySizeMB = [math]::Round($process.PrivateMemorySize / 1MB, 2)
    Write-Host "Process: $($process.ProcessName) | Working Set: $workingSetMB MB | Private Memory: $privateMemorySizeMB MB"
}
Write-Host ""


######------------------------------------------------GPU----------------------------------------------------######
# Check if a GPU is present
$gpuCount = (Get-WmiObject -Class Win32_VideoController).Count

if ($gpuCount -eq 0) {
    Write-Host "System has no GPU. Skipping GPU information." -ForegroundColor Yellow
} else {

$nvidiaSmiOutput = nvidia-smi --query-gpu=timestamp,name,driver_version,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used,fan.speed,power.management,power.limit,power.draw.average --format=csv

# Parse the output
$gpuInfo = $nvidiaSmiOutput | ConvertFrom-Csv

# Display GPU information
foreach ($gpu in $gpuInfo) {
    $name = $gpu.name
    $driverVersion = $gpu.driver_version
    $temperature = $gpu.'temperature.gpu'
    $utilizationGPU = $gpu.'utilization.gpu [%]'
    $utilizationMemory = $gpu.'utilization.memory [%]'
    $memoryTotal = $gpu.'memory.total [MiB]'
    $memoryFree = $gpu.'memory.free [MiB]'
    $memoryUsed = $gpu.'memory.used [MiB]'
    $fanSpeed = $gpu.'fan.speed [%]'
    $powerManagement = $gpu.'power.management'
    $powerLimit = $gpu.'power.limit [W]'
    $AveragePower = $gpu.'power.draw.average [W]'
    
    Write-Host "GPU Information:" -ForegroundColor Yellow
    Write-Host "------------------------"
    Write-Host "GPU Name: $name"
    Write-Host "Driver Version: $driverVersion"
    Write-Host "Temperature: $temperature C"
    Write-Host "Utilization GPU: $utilizationGPU"
    Write-Host "Utilization Memory: $utilizationMemory"
    Write-Host "Memory Total: $memoryTotal"
    Write-Host "Memory Free: $memoryFree"
    Write-Host "Memory Used: $memoryUsed"
    Write-Host "Fan Speed: $fanSpeed"
    Write-Host "Power Management: $powerManagement"
    Write-Host "Power Limit: $powerLimit"
    Write-Host "Average Power Drawn: $AveragePower"
    Write-Host ""
    # You can get a complete list of the query arguments by issuing: nvidia-smi --help-query-gpu, nvidia-smi --help-query-compute-apps
}

# Display the list of current running processes
$gpu_running_processes = nvidia-smi --query-compute-apps=pid,name,used_memory --format=csv

# Split the CSV output into lines and iterate through each line
Write-Host "GPU Running Processes:" -ForegroundColor Yellow
Write-Host "------------------------"
$gpu_running_processes | ForEach-Object {
    # Split the line into columns using commas as the delimiter
    $columns = $_.Split(',')

    # Extract the relevant information from the columns
    $processId = $columns[0].Trim()
    $process_name = $columns[1].Trim()
    # $used_memory = $columns[2].Trim()

    # Format and display the information for each process
    Write-Host "PID: $processId"
    Write-Host "Process Name: $process_name"
    # Write-Host "Used GPU Memory: $used_memory"
    # Write-Host ""
} }

######------------------------------------------------NETWORK CONN----------------------------------------------------######

# Get the active network interface
$networkInterface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1

if ($networkInterface) {
    # Network Type (Adapter Name)
    $networkType = $networkInterface.Name

    # Device Type
    $deviceType = $networkInterface.InterfaceDescription

    # SSID (for Wi-Fi)
    $ssid = $null
    if ($networkInterface.InterfaceOperationalStatus -eq 'Up' -and $networkInterface.MediaType -eq '802.11') {
        $ssid = (Get-NetConnectionProfile -InterfaceAlias $networkInterface.Name).Name
    }

    # Connection Type
    $connectionType = $networkInterface.MediaConnectionState

    # IPv4 Address
    $ipv4Address = $networkInterface | Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixLength -eq 24 } | Select-Object -ExpandProperty IPAddress

    # IPv6 Address
    $ipv6Address = $networkInterface | Get-NetIPAddress -AddressFamily IPv6 | Where-Object { $_.PrefixLength -eq 64 } | Select-Object -ExpandProperty IPAddress

    # Average Throughput (Mbps)
    $averageThroughput = if ($networkInterface.ReceiveLinkSpeed) { $networkInterface.ReceiveLinkSpeed / 1e6 } else { 'N/A' }

    # Display Network Information
    Write-Host ""
    Write-Host "Current Network Interface Information:" -ForegroundColor Yellow
    Write-Host "------------------------"
    Write-Host "Network Type (Adapter Name): $networkType"
    Write-Host "Device Type: $deviceType"
    Write-Host "SSID: $ssid"
    # Write-Host "DNS Name: $dnsName"
    Write-Host "Connection Type: $connectionType"
    Write-Host "IPv4 Address: $ipv4Address"
    Write-Host "IPv6 Address: $ipv6Address"
    Write-Host "Average Throughput: $averageThroughput Mbps"
} else {
    Write-Host "No active network interface found."
}

Write-Host ""
# Specify the target host or IP address
$targetHost = "example.com"

# Specify the number of ping packets to send
$pingCount = 10

# Specify the size of each ping packet (in bytes)
$packetSize = 500  # Adjust this to the desired packet size

# Perform a series of ping tests
$pingResults = Test-Connection -ComputerName $targetHost -Count $pingCount -BufferSize $packetSize

# Calculate average latency (ping time)
$averageLatency = ($pingResults | Measure-Object ResponseTime -Average).Average

# Calculate packet loss percentage
$packetLoss = ($pingResults | Where-Object { $_.StatusCode -ne "0" }).Count / $pingResults.Count * 100

# Calculate jitter (standard deviation of latency)
$latencyValues = $pingResults.ResponseTime
$latencyMean = $latencyValues | Measure-Object -Average | Select-Object -ExpandProperty Average
$latencySquaredErrors = $latencyValues | ForEach-Object { ($_ - $latencyMean) * ($_ - $latencyMean) }
$latencyVariance = ($latencySquaredErrors | Measure-Object -Average).Average
$jitter = [math]::Sqrt($latencyVariance)

# Display the results
Write-Host "Network Performance Metrics:" -ForegroundColor Yellow
Write-Host "------------------------"
Write-Host "Ping to $($targetHost) with packet size of $($packetSize) bytes:"
Write-Host "  - Average Latency: $averageLatency ms"
Write-Host "  - Jitter: $jitter ms"
Write-Host "  - Packet Loss: $packetLoss%"
Write-Host ""

######------------------------------------------------OS Info----------------------------------------------------######

# Collect OS information
$osInfo = Get-ComputerInfo

# Extract individual properties
$osName = $osInfo.OsName
$osVersion = $osInfo.OsVersion
$localTime = Get-Date
$lastBootTime = $osInfo.OsLastBootUpTime
$uptime = $osInfo.OsUptime
$buildType = $osInfo.OsBuildType
$csDomainRole = $osInfo.CsDomainRole
$csWakeUpType = $osInfo.CsWakeUpType
$csWorkgroup = $osInfo.CsWorkgroup
$foregroundAppBoost = $osInfo.OsForegroundApplicationBoost
$numberOfUsers = $osInfo.OsNumberofUsers
$osArchitecture = $osInfo.OsArchitecture
$osLanguage = $osInfo.OsLanguage
$timeZone = $osInfo.Timezone
$powerPlatformRole = $osInfo.PowerPlatformRole
$encryptionLevel = $osInfo.OsEncryptionLevel

# Display OS Information
Write-Host "Operating System Info:" -ForegroundColor Yellow
Write-Host "------------------------"
Write-Host "OS Name: $osName"
Write-Host "OS Version: $osVersion"
Write-Host "OS Local Time: $localTime"
Write-Host "OS Last Boot Uptime: $lastBootTime"
Write-Host "OS Uptime: $uptime"
Write-Host "OS Build Type: $buildType"
Write-Host "Domain Role: $csDomainRole"
Write-Host "Wake-Up Type: $csWakeUpType"
Write-Host "Workgroup: $csWorkgroup"
Write-Host "Foreground Application Boost: $foregroundAppBoost"
Write-Host "Number of Users: $numberOfUsers"
Write-Host "OS Architecture: $osArchitecture"
Write-Host "OS Language: $osLanguage"
Write-Host "Timezone: $timeZone"
Write-Host "Power Platform Role: $powerPlatformRole"
Write-Host "OS Encryption Level: $encryptionLevel"
Write-Host ""

######------------------------------------------------Power/Battery Info----------------------------------------------------######

# Check if the computer is a laptop or desktop
Write-Host "Power/Battery Info:" -ForegroundColor Yellow
Write-Host "------------------------"
$computerSystem = Get-WmiObject -Class Win32_ComputerSystem
$isLaptop = $computerSystem.PCSystemType -eq 2

if ($isLaptop) {
    # Get battery information
    $battery = Get-WmiObject -Class Win32_Battery

    # Check if the battery is present
    if ($battery) {
        $batteryLevel = $battery.EstimatedChargeRemaining
        $batteryStatus = $battery.BatteryStatus

        # Check if the laptop is currently charging
        $isCharging = $batteryStatus -eq 2

        # Display battery information
        Write-Host "Battery Level: $batteryLevel%"
        if ($isCharging) {
            Write-Host "Charging: Yes"
        } else {
            Write-Host "Charging: No"
        }
    } else {
        Write-Host "Battery not detected."
    }
} else {
    # Display message for desktop computers
    Write-Host "This is a desktop computer."
}

######------------------------------------------------Script Ends----------------------------------------------------######
