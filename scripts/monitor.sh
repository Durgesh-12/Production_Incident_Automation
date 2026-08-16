#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================="
echo " Production Monitor"
echo "=========================="

echo
echo "Running Server Health Check..."
"$SCRIPT_DIR/server_health.sh"

echo
echo "Running Incident Engine..."
"$SCRIPT_DIR/incident_engine.sh"
