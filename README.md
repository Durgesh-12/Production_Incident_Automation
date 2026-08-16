# Production Incident Automation Framework

A Bash-based production incident monitoring and automation framework that monitors a Linux server, detects infrastructure incidents, classifies their severity, creates Jira incidents automatically, prevents duplicate tickets, and resolves incidents when the system recovers.

The project demonstrates a practical **DevOps / SRE incident-management workflow** using Linux, Bash scripting, monitoring, incident classification, and Jira REST API integration.

---

## 🚀 Project Overview

The framework continuously evaluates the health of a Linux server and checks:

* CPU usage
* Memory usage
* Disk usage
* Load average
* Application/service health
* Network interface health
* Network connectivity
* Port availability

Based on configurable health conditions, the system classifies incidents as **P1, P2, P3, or no incident**.

When an incident is detected, the framework automatically creates a Jira issue.

It also includes:

* Duplicate incident protection
* Incident state tracking
* Jira incident recovery
* Automatic Jira resolution when the incident recovers

---

## 🏗️ Architecture

```text
                    Linux Server
                         │
                         ▼
               ┌───────────────────┐
               │ server_health.sh   │
               │                   │
               │ CPU               │
               │ Memory            │
               │ Disk              │
               │ Load              │
               │ Service           │
               │ Network           │
               │ Port              │
               └─────────┬─────────┘
                         │
                         ▼
                health_status.env
                         │
                         ▼
               ┌───────────────────┐
               │ incident_engine.sh│
               │                   │
               │ Incident Detection│
               │ Severity           │
               │ P1 / P2 / P3       │
               │ Duplicate Check    │
               │ Recovery Detection │
               └─────────┬─────────┘
                         │
             ┌───────────┴────────────┐
             │                        │
        Incident                  Recovery
             │                        │
             ▼                        ▼
   jira_integration.sh       Jira Resolution
             │
             ▼
        Jira Cloud
             │
             ▼
       Incident Ticket
```

---

## ✨ Key Features

### Server Health Monitoring

Collects and evaluates:

* CPU utilization
* Memory utilization
* Disk utilization
* Load average
* SSH service status
* Network interface status
* Connectivity
* Port 22 availability

### Incident Classification

The framework automatically determines incident severity.

| Condition                        | Priority    |
| -------------------------------- | ----------- |
| Two or more critical resources   | P1          |
| Important service unavailable    | P2          |
| One critical resource            | P2          |
| Non-critical service unavailable | P3          |
| Warning threshold only           | No incident |

---

## 🎯 Incident Workflow

### Healthy System

```text
Server Health
     ↓
HEALTHY
     ↓
No Incident
     ↓
No Jira Ticket
```

### P2 Incident

```text
Critical Resource
       ↓
Incident Detected
       ↓
P2 Classification
       ↓
Duplicate Check
       ↓
Create Jira Issue
```

### P1 Incident

```text
Multiple Critical Resources
       ↓
P1 Classification
       ↓
Create Jira Issue
```

### P3 Incident

```text
Non-Critical Service Down
       ↓
P3 Classification
       ↓
Create Jira Issue
```

### Recovery

```text
Incident Active
       ↓
Server Recovers
       ↓
Recovery Detected
       ↓
Jira Issue → Done
       ↓
Incident State Cleared
```

---

## 🛡️ Duplicate Incident Protection

A production monitoring system should not create hundreds of Jira tickets for the same ongoing incident.

This project maintains an incident state file:

```text
logs/incident_state.env
```

The framework generates an incident signature:

```text
P2|One critical resource issue
```

If the same incident is detected again, the framework checks the existing state and prevents creation of another Jira issue.

Example:

```text
Jira Integration
Duplicate incident detected
Existing Jira incident : PIA-11
No new Jira issue created
```

This prevents repeated monitoring cycles from generating duplicate incidents.

---

## 🔄 Incident Recovery

When the system returns to a healthy state, the framework detects that the active incident has recovered.

It then resolves the associated Jira issue using the Jira transition API.

Example:

```text
Incident recovery detected
Existing Jira incident : PIA-13
Resolving Jira incident...

Jira Resolution
Jira Issue : PIA-13
Transition : Done
Jira Issue Resolved : PIA-13
Status              : Done

Incident state cleared
```

This creates a complete incident lifecycle:

```text
Detect → Classify → Create → Monitor → Recover → Resolve
```

---

## 📁 Project Structure

```text
Production_Incident_Automation/
│
├── config/
│   └── jira.conf              # Local Jira credentials/configuration
│
├── docs/
│
├── logs/
│   └── test/                  # Test health-status scenarios
│
├── reports/
│
├── scripts/
│   ├── server_health.sh       # Server health monitoring
│   ├── incident_engine.sh     # Incident classification & state management
│   ├── jira_integration.sh    # Jira REST API integration
│   └── monitor.sh             # Main monitoring workflow
│
├── test.sh
├── Project_Design.md
├── README.md
└── LICENSE
```

---

## ⚙️ Prerequisites

The project is designed for a Linux environment.

Required tools:

* Bash
* curl
* awk
* sed
* grep
* systemctl
* iostat
* free
* df
* uptime
* nproc
* nc
* Git
* Jira Cloud account
* Jira API token

On Ubuntu, required monitoring utilities can be installed with:

```bash
sudo apt update
sudo apt install sysstat netcat-openbsd curl
```

---

## 🔐 Jira Configuration

Create the local configuration file:

```text
config/jira.conf
```

Example:

```bash
JIRA_URL="https://your-domain.atlassian.net"
JIRA_PROJECT_KEY="PIA"
JIRA_EMAIL="your-email@example.com"
JIRA_API_TOKEN="your-api-token"
```

**Do not commit this file to Git.**

The project `.gitignore` excludes:

```text
config/jira.conf
```

The API token should never be hardcoded into scripts or committed to the public repository.

---

## ▶️ Running the Monitoring System

Make the scripts executable:

```bash
chmod +x scripts/*.sh
```

Run the complete monitoring workflow:

```bash
./scripts/monitor.sh
```

The workflow performs:

```text
Server Health Check
        ↓
Health Status File
        ↓
Incident Engine
        ↓
Incident Classification
        ↓
Jira Integration
```

---

## 🧪 Testing

The project includes predefined test scenarios.

### P2 — One Critical Resource

```bash
./scripts/incident_engine.sh logs/test/p2_resource.env
```

Expected:

```text
Incident Detected : YES
Incident Priority : P2
Incident Reason   : One critical resource issue
```

A Jira issue is created.

---

### P1 — Multiple Critical Resources

```bash
./scripts/incident_engine.sh logs/test/p1_multiple.env
```

Expected:

```text
Incident Detected : YES
Incident Priority : P1
Incident Reason   : Multiple critical resource issues
```

---

### P3 — Non-Critical Service Down

```bash
./scripts/incident_engine.sh logs/test/p3_service.env
```

Expected:

```text
Incident Detected : YES
Incident Priority : P3
Incident Reason   : Non-critical service down
```

---

### Warning — No Jira Incident

```bash
./scripts/incident_engine.sh logs/test/warning.env
```

Expected:

```text
Incident Detected : NO
Incident Priority : NONE
Incident Reason   : Warning threshold reached

No Jira issue created
```

---

## 🔁 Duplicate Protection Test

Run the same incident twice:

```bash
./scripts/incident_engine.sh logs/test/p2_resource.env
```

First execution:

```text
Jira Issue Created : PIA-11
```

Second execution:

```text
Duplicate incident detected
Existing Jira incident : PIA-11
No new Jira issue created
```

This confirms that the framework does not create duplicate Jira incidents for the same active condition.

---

## 🧹 Incident Recovery Test

After an active incident, run a healthy/warning scenario:

```bash
./scripts/incident_engine.sh logs/test/warning.env
```

Expected behavior:

```text
Incident recovery detected
Resolving Jira incident...
Jira Issue Resolved : PIA-11
Status              : Done
Incident state cleared
```

---

## 🔒 Security

Sensitive Jira configuration is intentionally excluded from Git.

The following file is ignored:

```text
config/jira.conf
```

Never commit:

* Jira API tokens
* Passwords
* Access keys
* Private credentials
* Production secrets

For production deployments, credentials should preferably be supplied through a secure secret-management mechanism.

---

## 📊 Incident Severity Model

```text
                 ┌─────────────────────┐
                 │   Health Evaluation │
                 └──────────┬──────────┘
                            │
                 ┌──────────▼──────────┐
                 │ Critical Resources? │
                 └──────────┬──────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
          >= 2 Critical               1 Critical
              │                           │
              ▼                           ▼
             P1                          P2
              │
              │
              └──────────────┐
                             │
                     Service Critical?
                             │
                  ┌──────────┴──────────┐
                  │                     │
              Important             Non-Critical
                  │                     │
                  ▼                     ▼
                 P2                    P3
```

---

## 🧰 Technologies Used

| Technology   | Purpose                     |
| ------------ | --------------------------- |
| Linux        | Server environment          |
| Bash         | Automation and scripting    |
| iostat       | CPU monitoring              |
| free         | Memory monitoring           |
| df           | Disk monitoring             |
| uptime       | Load monitoring             |
| systemctl    | Service monitoring          |
| nc           | Port monitoring             |
| curl         | Jira REST API communication |
| Jira Cloud   | Incident management         |
| Git / GitHub | Version control             |

---

## 🎓 What This Project Demonstrates

This project demonstrates practical knowledge of:

* Linux administration
* Bash scripting
* System monitoring
* Shell automation
* Incident classification
* Production troubleshooting concepts
* REST API integration
* Jira automation
* State management
* Duplicate detection
* Incident recovery
* Git version control
* Secure configuration handling
* DevOps / SRE practices

---

## 🚀 Future Enhancements

Possible future improvements include:

* Alert notifications through email or Slack
* Prometheus/Grafana integration
* Application-level health checks
* Database monitoring
* Persistent incident database
* Configurable service importance
* Configurable monitoring thresholds
* CloudWatch integration
* Container monitoring
* Multi-server monitoring

The current implementation intentionally focuses on a **single Linux server** to keep the monitoring and incident lifecycle clear and maintainable.

---

## 📌 Project Status

**Status: Completed**

Current capabilities:

* ✅ Server health monitoring
* ✅ CPU monitoring
* ✅ Memory monitoring
* ✅ Disk monitoring
* ✅ Load monitoring
* ✅ Service monitoring
* ✅ Network monitoring
* ✅ Incident classification
* ✅ P1/P2/P3 severity
* ✅ Jira issue creation
* ✅ Duplicate incident protection
* ✅ Incident state tracking
* ✅ Automatic incident recovery
* ✅ Jira issue resolution
* ✅ Secure Jira configuration handling
* ✅ Git version control

---

## 👨‍💻 Author

**Durgesh Chouter**

This project was developed as a hands-on DevOps/SRE automation project to demonstrate Linux monitoring, Bash automation, incident management, and Jira API integration.

---

## ⭐ If You Find This Project Useful

Feel free to explore the repository, provide feedback, or suggest improvements.

If you find the project useful, consider giving it a ⭐ on GitHub.
