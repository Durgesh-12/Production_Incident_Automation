#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_DIR/reports"

mkdir -p "$REPORT_DIR"

REPORT_TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT_FILE="$REPORT_DIR/server_health_$REPORT_TIMESTAMP.txt"
exec > >(tee "$REPORT_FILE") 2>&1

LOG_DIR="$PROJECT_DIR/logs"
HEALTH_STATUS_FILE="$LOG_DIR/health_status.env"

mkdir -p "$LOG_DIR"

echo "=========================="
echo "   Server Health Report"
echo "=========================="

timestamp=$(date)
echo "Timestamp : $timestamp"

host_name=$(hostname)
echo "Hostname  : $host_name"

echo
echo "CPU Usage"

cpu_idle=$(iostat | awk '/%idle/ {getline; print $6}')
cpu_usage=$(awk "BEGIN {print 100 - $cpu_idle}")

echo "CPU Idle  : $cpu_idle%"
echo "CPU Usage : $cpu_usage%"

if awk -v cpu="$cpu_usage" 'BEGIN {exit !(cpu >= 90)}'; then
    cpu_status="CRITICAL"
elif awk -v cpu="$cpu_usage" 'BEGIN {exit !(cpu >= 75)}'; then
    cpu_status="WARNING"
else
    cpu_status="HEALTHY"
fi
echo "CPU Status : $cpu_status"
echo
echo "Memory Usage"

memory_total=$(free -m | awk '/^Mem:/ {print $2}')
memory_available=$(free -m | awk '/^Mem:/ {print $7}')

memory_usage=$(awk -v total="$memory_total" -v available="$memory_available" 'BEGIN {printf "%.2f", ((total - available) / total) * 100}')

echo "Memory Total     : $memory_total MB"
echo "Memory Available : $memory_available MB"
echo "Memory Usage     : $memory_usage%"
if awk -v memory="$memory_usage" 'BEGIN {exit !(memory >= 90)}'; then
    memory_status="CRITICAL"
elif awk -v memory="$memory_usage" 'BEGIN {exit !(memory >= 75)}'; then
    memory_status="WARNING"
else
    memory_status="HEALTHY"
fi

echo "Memory Status    : $memory_status"
echo
echo "Disk Usage"

disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

echo "Disk Usage : $disk_usage%"
if awk -v disk="$disk_usage" 'BEGIN {exit !(disk >= 90)}'; then
    disk_status="CRITICAL"
elif awk -v disk="$disk_usage" 'BEGIN {exit !(disk >= 75)}'; then
    disk_status="WARNING"
else
    disk_status="HEALTHY"
fi
echo "Disk Status : $disk_status"
echo
echo "Load Average"

cpu_cores=$(nproc)
load_1min=$(uptime | awk -F'load average: ' '{print $2}' | cut -d',' -f1 | xargs)

load_ratio=$(awk -v load_value="$load_1min" -v cores="$cpu_cores" 'BEGIN {printf "%.2f", load_value / cores}')

echo "CPU Cores   : $cpu_cores"
echo "Load (1min) : $load_1min"
echo "Load Ratio  : $load_ratio"

if awk -v ratio="$load_ratio" 'BEGIN {exit !(ratio >= 1)}'; then
    load_status="CRITICAL"
elif awk -v ratio="$load_ratio" 'BEGIN {exit !(ratio >= 0.70)}'; then
    load_status="WARNING"
else
    load_status="HEALTHY"
fi

echo "Load Status : $load_status"
echo
echo "Uptime"

uptime_info=$(uptime -p)

echo "Uptime : $uptime_info"
echo
echo "Application / Service"

service_name="ssh.service"
service_status=$(systemctl is-active "$service_name")

echo "Service        : $service_name"
echo "Service Status : $service_status"

echo
echo "Network Monitoring"

# Network Interface
network_interface=$(ip route | awk '/default/ {print $5; exit}')

if ip link show "$network_interface" | grep -q "state UP"; then
    interface_status="HEALTHY"
else
    interface_status="CRITICAL"
fi

echo "Interface        : $network_interface"
echo "Interface Status : $interface_status"

# Network Connectivity
if ping -c 3 -W 2 8.8.8.8 >/dev/null 2>&1; then
    connectivity_status="HEALTHY"
else
    connectivity_status="CRITICAL"
fi

echo "Connectivity     : $connectivity_status"

# Port Availability
if nc -z localhost 22 >/dev/null 2>&1; then
    port_status="OPEN"
    port_health="HEALTHY"
else
    port_status="CLOSED"
    port_health="CRITICAL"
fi

echo "Port             : 22"
echo "Port Status      : $port_status"
echo "Port Health      : $port_health"

if [ "$service_status" = "active" ]; then
    service_health="HEALTHY"
else
    service_health="CRITICAL"
fi
echo "Service Health : $service_health"
echo
echo "Overall Server Health"

overall_status="HEALTHY"

if [ "$service_health" = "CRITICAL" ]; then
    overall_status="CRITICAL"
elif [ "$cpu_status" = "CRITICAL" ] ||
     [ "$memory_status" = "CRITICAL" ] ||
     [ "$disk_status" = "CRITICAL" ] ||
     [ "$load_status" = "CRITICAL" ]; then
    overall_status="CRITICAL"
elif [ "$cpu_status" = "WARNING" ] ||
     [ "$memory_status" = "WARNING" ] ||
     [ "$disk_status" = "WARNING" ] ||
     [ "$load_status" = "WARNING" ]; then
    overall_status="WARNING"
fi

echo "Overall Status : $overall_status"
echo

service_importance="IMPORTANT"

cat > "$HEALTH_STATUS_FILE" <<EOF
CPU_STATUS=$cpu_status
MEMORY_STATUS=$memory_status
DISK_STATUS=$disk_status
LOAD_STATUS=$load_status
SERVICE_STATUS=$service_status
SERVICE_HEALTH=$service_health
SERVICE_IMPORTANCE=$service_importance
OVERALL_STATUS=$overall_status
EOF
