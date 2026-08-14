#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CONFIG_FILE="$PROJECT_DIR/config/jira.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Jira configuration not found"
    exit 1
fi

source "$CONFIG_FILE"

if [ -z "$JIRA_URL" ] ||
   [ -z "$JIRA_PROJECT_KEY" ] ||
   [ -z "$JIRA_EMAIL" ] ||
   [ -z "$JIRA_API_TOKEN" ]; then
    echo "ERROR: Jira configuration is incomplete"
    exit 1
fi

INCIDENT_PRIORITY="${1:-P2}"
INCIDENT_REASON="${2:-Production incident detected}"

SUMMARY="[$INCIDENT_PRIORITY] Production Incident Detected"

DESCRIPTION="Production Incident Automation detected an incident.

Priority: $INCIDENT_PRIORITY
Reason: $INCIDENT_REASON

Server: $(hostname)
Timestamp: $(date)"

PAYLOAD=$(cat <<EOF
{
  "fields": {
    "project": {
      "key": "$JIRA_PROJECT_KEY"
    },
    "summary": "[$INCIDENT_PRIORITY] Production Incident Detected",
    "description": {
      "type": "doc",
      "version": 1,
      "content": [
        {
          "type": "paragraph",
          "content": [
            {
              "type": "text",
              "text": "Production Incident Automation detected an incident. Priority: $INCIDENT_PRIORITY. Reason: $INCIDENT_REASON. Server: $(hostname). Timestamp: $(date)"
            }
          ]
        }
      ]
    },
    "issuetype": {
      "name": "Task"
    }
  }
}
EOF
)

echo "=========================="
echo "   Jira Integration"
echo "=========================="

response=$(curl -s \
    -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -X POST \
    "$JIRA_URL/rest/api/3/issue" \
    --data "$PAYLOAD")

issue_key=$(echo "$response" | sed -n 's/.*"key":"\([^"]*\)".*/\1/p')

if [ -n "$issue_key" ]; then
    echo "Jira Issue Created : $issue_key"
    echo "Priority           : $INCIDENT_PRIORITY"
    echo "Reason             : $INCIDENT_REASON"
else
    echo "ERROR: Failed to create Jira issue"
    echo "Response: $response"
    exit 1
fi
