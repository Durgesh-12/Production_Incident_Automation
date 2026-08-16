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

ACTION="${1:-create}"

# ============================================================
# RESOLVE JIRA INCIDENT
# ============================================================

if [ "$ACTION" = "resolve" ]; then

    ISSUE_KEY="$2"

    if [ -z "$ISSUE_KEY" ]; then
        echo "ERROR: Jira issue key required"
        exit 1
    fi

    echo "=========================="
    echo "   Jira Resolution"
    echo "=========================="

    echo "Jira Issue : $ISSUE_KEY"
    echo "Transition : Done"

    PAYLOAD='{
      "transition": {
        "id": "41"
      }
    }'

    response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" \
        -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -X POST \
        "$JIRA_URL/rest/api/3/issue/$ISSUE_KEY/transitions" \
        --data "$PAYLOAD")

    http_status=$(echo "$response" | sed -n 's/.*HTTP_STATUS:\([0-9]*\)$/\1/p')

    if [ "$http_status" = "204" ]; then
        echo "Jira Issue Resolved : $ISSUE_KEY"
        echo "Status              : Done"
        exit 0
    else
        echo "ERROR: Failed to resolve Jira issue"
        echo "$response"
        exit 1
    fi
fi

# ============================================================
# CREATE JIRA INCIDENT
# ============================================================

INCIDENT_PRIORITY="${1:-P2}"
INCIDENT_REASON="${2:-Production incident detected}"

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
