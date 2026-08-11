#!/bin/bash

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
cpu_status="WARNING"
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
echo "Incident Classification"

incident_detected="NO"
incident_priority="NONE"
incident_reason="No incident detected"

critical_count=0

[ "$cpu_status" = "CRITICAL" ] && ((critical_count++))
[ "$memory_status" = "CRITICAL" ] && ((critical_count++))
[ "$disk_status" = "CRITICAL" ] && ((critical_count++))
[ "$load_status" = "CRITICAL" ] && ((critical_count++))

# SSH is currently treated as an important infrastructure service
service_importance="IMPORTANT"
if [ "$critical_count" -ge 2 ]; then

    incident_detected="YES"
    incident_priority="P1"
    incident_reason="Multiple critical resource issues"

elif [ "$service_health" = "CRITICAL" ] && [ "$service_importance" = "IMPORTANT" ]; then

    incident_detected="YES"
    incident_priority="P2"
    incident_reason="Important service down"

elif [ "$critical_count" -eq 1 ]; then

    incident_detected="YES"
    incident_priority="P2"
    incident_reason="One critical resource issue"

elif [ "$service_health" = "CRITICAL" ] && [ "$service_importance" = "NON_CRITICAL" ]; then

    incident_detected="YES"
    incident_priority="P3"
    incident_reason="Non-critical service down"

elif [ "$overall_status" = "WARNING" ]; then

    incident_detected="NO"
    incident_priority="NONE"
    incident_reason="Warning threshold reached"

fi

echo "Incident Detected : $incident_detected"
echo "Incident Priority : $incident_priority"
echo "Incident Reason   : $incident_reason"
