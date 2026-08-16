#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ "$#" -eq 1 ]; then
    HEALTH_STATUS_FILE="$1"
else
    HEALTH_STATUS_FILE="$PROJECT_DIR/logs/health_status.env"
fi

if [ ! -f "$HEALTH_STATUS_FILE" ]; then
    echo "ERROR: Health status file not found"
    echo "Expected: $HEALTH_STATUS_FILE"
    exit 1
fi

source "$HEALTH_STATUS_FILE"


echo "=========================="
echo "   Incident Engine"
echo "=========================="

echo "CPU Status           : $CPU_STATUS"
echo "Memory Status        : $MEMORY_STATUS"
echo "Disk Status          : $DISK_STATUS"
echo "Load Status          : $LOAD_STATUS"
echo "Service Status       : $SERVICE_STATUS"
echo "Service Health       : $SERVICE_HEALTH"
echo "Service Importance   : $SERVICE_IMPORTANCE"
echo "Overall Status       : $OVERALL_STATUS"

critical_count=0

[ "$CPU_STATUS" = "CRITICAL" ] && ((critical_count++))
[ "$MEMORY_STATUS" = "CRITICAL" ] && ((critical_count++))
[ "$DISK_STATUS" = "CRITICAL" ] && ((critical_count++))
[ "$LOAD_STATUS" = "CRITICAL" ] && ((critical_count++))

echo
echo "Critical Resources  : $critical_count"

incident_detected="NO"
incident_priority="NONE"
incident_reason="No incident detected"

if [ "$critical_count" -ge 2 ]; then

    incident_detected="YES"
    incident_priority="P1"
    incident_reason="Multiple critical resource issues"

elif [ "$SERVICE_HEALTH" = "CRITICAL" ] &&
     [ "$SERVICE_IMPORTANCE" = "IMPORTANT" ]; then

    incident_detected="YES"
    incident_priority="P2"
    incident_reason="Important service down"

elif [ "$critical_count" -eq 1 ]; then

    incident_detected="YES"
    incident_priority="P2"
    incident_reason="One critical resource issue"

elif [ "$SERVICE_HEALTH" = "CRITICAL" ] &&
     [ "$SERVICE_IMPORTANCE" = "NON_CRITICAL" ]; then

    incident_detected="YES"
    incident_priority="P3"
    incident_reason="Non-critical service down"

elif [ "$OVERALL_STATUS" = "WARNING" ]; then

    incident_detected="NO"
    incident_priority="NONE"
    incident_reason="Warning threshold reached"

fi

echo
echo "Incident Classification"
echo "Incident Detected : $incident_detected"
echo "Incident Priority : $incident_priority"
echo "Incident Reason   : $incident_reason"
echo

STATE_FILE="$PROJECT_DIR/logs/incident_state.env"

if [ "$incident_detected" = "YES" ]; then

    current_signature="${incident_priority}|${incident_reason}"

    previous_signature=""

    if [ -f "$STATE_FILE" ]; then
          previous_signature=$(grep '^INCIDENT_SIGNATURE=' "$STATE_FILE" | cut -d'"' -f2)
          existing_jira_issue=$(grep '^JIRA_ISSUE_KEY=' "$STATE_FILE" | cut -d'"' -f2)
    fi

    if [ "$current_signature" = "$previous_signature" ]; then

        echo "Jira Integration"
        echo "Duplicate incident detected"
        echo "Existing Jira incident : $existing_jira_issue"
        echo "No new Jira issue created"

    else

        echo "Jira Integration"
        echo "Creating Jira incident..."

        jira_output=$(
            "$SCRIPT_DIR/jira_integration.sh" \
                "$incident_priority" \
                "$incident_reason"
        )

        echo "$jira_output"

        jira_issue_key=$(echo "$jira_output" | \
            sed -n 's/.*Jira Issue Created : \([^ ]*\).*/\1/p')

        if [ -n "$jira_issue_key" ]; then

            cat > "$STATE_FILE" <<EOF
INCIDENT_SIGNATURE="$current_signature"
INCIDENT_PRIORITY="$incident_priority"
INCIDENT_REASON="$incident_reason"
JIRA_ISSUE_KEY="$jira_issue_key"
EOF

            echo "Incident state saved"

        else
            echo "WARNING: Jira issue key not found"
            echo "Incident state not saved"
        fi

    fi

else

    echo "Jira Integration"

    if [ -f "$STATE_FILE" ]; then

        existing_jira_issue=$(grep '^JIRA_ISSUE_KEY=' "$STATE_FILE" | cut -d'"' -f2)

        if [ -n "$existing_jira_issue" ]; then

            echo "Incident recovery detected"
            echo "Existing Jira incident : $existing_jira_issue"
            echo "Resolving Jira incident..."

            resolve_output=$(
                "$SCRIPT_DIR/jira_integration.sh" \
                    resolve \
                    "$existing_jira_issue"
            )

            echo "$resolve_output"

            if echo "$resolve_output" | grep -q "Jira Issue Resolved"; then
                rm -f "$STATE_FILE"
                echo "Incident state cleared"
            else
                echo "WARNING: Jira issue was not resolved"
                echo "Incident state retained"
            fi

        else

            echo "No Jira issue associated with incident"
            rm -f "$STATE_FILE"
            echo "Incident state cleared"

        fi

    else

        echo "No active Jira incident"
        echo "No Jira issue created"

    fi

fi
