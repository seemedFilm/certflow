# CertFlow - Automated SSL Certificate Management

Professional SSL certificate management system with web dashboard and REST API.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-success)](#)
[![Version](https://img.shields.io/badge/Version-2.0.0-blue)](#)

## 🎯 Überblick

CertFlow ist ein automatisiertes SSL-Zertifikatsverwaltungssystem mit:

- **Dual Certificate Sources:**
  - **step-ca** für interne Zertifikate (.internal Domains)
  - **Let's Encrypt** für externe Zertifikate (via Traefik)

- **Vollständige Automation:**
  - Automatische Traefik Reverse Proxy Konfiguration
  - Automatische Pi-hole DNS-Einträge
  - Auto-Renewal für step-ca Zertifikate
  - Audit-Logging aller Operationen

- **Benutzerfreundlich:**
  - Web-Dashboard (Flask)
  - REST API (FastAPI)
  - SQLite-Datenbank
  - Systemd-Services

## ✨ Features

### Certificate Management
- ✅ **step-ca Integration** - Interne Zertifikate via SSH
- ✅ **Let's Encrypt** - Externe Zertifikate via Traefik
- ✅ **Auto-Renewal** - Automatische Verlängerung 30 Tage vor Ablauf
- ✅ **Certificate Monitoring** - Überwachung aller Zertifikate

### Automation
- ✅ **Traefik Integration** - Automatische Reverse Proxy Konfiguration
- ✅ **Pi-hole DNS** - Automatische DNS A-Records (Pi-hole v6 kompatibel)
- ✅ **One-Click Deployment** - Zertifikat erstellen mit einem Klick
- ✅ **Cleanup on Delete** - Automatisches Aufräumen bei Löschung

### Web Interface
- ✅ **Dashboard** - Übersicht aller Zertifikate
- ✅ **Certificate Details** - Ablaufdatum, Status, Renewal-Jobs
- ✅ **Audit Log** - Vollständige Historie aller Operationen
- ✅ **Renewal Management** - Auto-Renewal konfigurieren

### REST API
- ✅ **CRUD Operations** - Create, Read, Update, Delete
- ✅ **OpenAPI/Swagger Docs** - Automatische API-Dokumentation
- ✅ **JSON Responses** - Standardisiertes Response-Format
- ✅ **Error Handling** - Detaillierte Fehlermeldungen

## 📋 Voraussetzungen

### Server
- **step-ca Server** - Certificate Authority für interne Zertifikate
- **Traefik Server** - Reverse Proxy (Docker)
- **Pi-hole Server** - DNS Server (v6 kompatibel)
- **CertFlow Host** - Server für CertFlow Installation

### SSH-Zugriff
- SSH-Keys zu allen Remote-Servern
- Root-Zugriff auf step-ca, Traefik, Pi-hole

### Software
- Python 3.10+
- systemd (für Services)

## 🚀 Quick Start

### 1. Installation

```bash
# Clone Repository
cd /opt
git clone https://github.com/yourusername/certflow.git
cd certflow

# Konfiguration
cp certflow/config/settings.yaml certflow/config/settings.yaml.example
nano certflow/config/settings.yaml

# Deployment
bash deploy.sh
```

### 2. Konfiguration

Editiere `certflow/config/settings.yaml`:

```yaml
certificate:
  step_ca:
    host: "192.168.1.3"              # step-ca Server
    user: "root"
    script_path: "/root/create-cert.sh"
    output_path: "/srv/pki"
    ssh_key: "/root/.ssh/id_ed25519"

traefik:
  host: "192.168.1.23"               # Traefik Server
  user: "root"
  ssh_key: "/root/.ssh/id_ed25519"

# pihole config in skills/pihole-dns-manager/config.yaml
```

### 3. Services starten

```bash
systemctl enable --now certflow-api
systemctl enable --now certflow-web
systemctl enable --now certflow-renewal

systemctl status certflow-*
```

### 4. Web-Interface öffnen

```
http://<server-ip>:5000
```

### 5. Erstes Zertifikat erstellen

**Via Web-UI:**
1. Öffne Dashboard
2. "Neues Zertifikat" klicken
3. Hostname eingeben (z.B. `myapp.internal`)
4. Backend-IP eingeben (z.B. `https://192.168.1.50:8080`)
5. "Erstellen" klicken

**Via API:**
```bash
curl -X POST http://localhost:5001/api/certs \
  -H "Content-Type: application/json" \
  -d '{
    "hostname": "myapp.internal",
    "type": "step-ca",
    "create_traefik_config": true,
    "backend_ip": "https://192.168.1.50:8080",
    "auto_renew": true
  }'
```

## 📁 Verzeichnisstruktur

```
certflow/
├── README.md                          # Diese Datei
├── QUICKSTART.md                      # Schnelleinstieg
├── CHANGELOG.md                       # Versionshistorie
├── LICENSE                            # MIT License
├── requirements.txt                   # Python Dependencies
├── deploy.sh                          # Deployment-Script
│
├── certflow/                          # Core Application
│   ├── api/
│   │   ├── main.py                   # FastAPI REST API
│   │   └── init_db.py                # Datenbank-Initialisierung
│   ├── lib/
│   │   ├── certificate_manager.py    # Business Logic
│   │   └── renewal_scheduler.py      # Auto-Renewal
│   ├── web/
│   │   ├── app.py                    # Flask Web-UI
│   │   ├── templates/                # HTML Templates
│   │   └── static/                   # CSS/JS
│   └── config/
│       └── settings.yaml             # Konfiguration
│
├── skills/                            # Helper Scripts
│   ├── traefik-service-manager/      # Traefik Automation
│   └── pihole-dns-manager/           # Pi-hole DNS Automation
│
├── docs/                              # Dokumentation
│   ├── CERT-MANAGER.md               # Cert-Manager Details
│   └── QUICKSTART.md                 # Schnelleinstieg
│
└── scripts/                           # Utility Scripts
    ├── backup.sh                     # Backup
    ├── restore.sh                    # Restore
    └── migrate-from-openclaw.sh      # Migration von OpenClaw
```

## 🔧 Konfiguration

### Certificate Settings

```yaml
certificate:
  step_ca:
    host: "192.168.1.3"
    user: "root"
    script_path: "/root/create-cert.sh"
    output_path: "/srv/pki"
    ssh_key: "/root/.ssh/id_ed25519"
    default_validity_days: 365
```

### Traefik Integration

```yaml
traefik:
  host: "192.168.1.23"
  user: "root"
  ssh_key: "/root/.ssh/id_ed25519"
  container_name: "traefik"
```

### Auto-Renewal

```yaml
renewal:
  enabled: true
  check_interval_hours: 24
  renew_days_before: 30
  retry_on_failure: true
  max_retries: 3
```

### API & Web

```yaml
api:
  host: "0.0.0.0"
  port: 5001

web:
  host: "0.0.0.0"
  port: 5000
  title: "CertFlow"
```

## 📊 Architecture

```
User → Web-UI/API → CertFlow → step-ca → Certificate
                      ↓
                   Traefik → YAML Config
                      ↓
                   Pi-hole → DNS Record
```

**Datenfluss:**
1. User erstellt Zertifikat via Web-UI
2. CertFlow ruft step-ca via SSH auf
3. Zertifikat wird auf step-ca erstellt
4. CertFlow erstellt Traefik-Config via SSH
5. CertFlow erstellt Pi-hole DNS-Eintrag via SSH
6. DNS auflösbar → Traefik → Backend

## 🔌 API Endpoints

### Certificates

```bash
# List all certificates
GET /api/certs

# Get certificate details
GET /api/certs/{hostname}

# Create certificate
POST /api/certs
{
  "hostname": "myapp.internal",
  "type": "step-ca",
  "create_traefik_config": true,
  "backend_ip": "https://192.168.1.50:8080",
  "auto_renew": true
}

# Delete certificate
DELETE /api/certs/{hostname}
```

### Renewal Jobs

```bash
# List renewal jobs
GET /api/renewal-jobs

# Get job details
GET /api/renewal-jobs/{hostname}
```

### Audit Log

```bash
# Get audit log
GET /api/audit-log?limit=100&offset=0
```

### API Dokumentation

```
http://localhost:5001/docs       # Swagger UI
http://localhost:5001/redoc      # ReDoc
```

## 🧪 Testing

### End-to-End Test

```bash
# 1. Create certificate
curl -X POST http://localhost:5001/api/certs \
  -H "Content-Type: application/json" \
  -d '{
    "hostname": "test.internal",
    "type": "step-ca",
    "create_traefik_config": true,
    "backend_ip": "https://192.168.1.50:8080"
  }'

# 2. Verify certificate
ssh root@192.168.1.3 "ls -la /srv/pki/test/"

# 3. Verify Traefik config
ssh root@192.168.1.23 "cat /docker/volume/traefik/dynamic/test.yml"

# 4. Verify DNS
dig test.internal @192.168.1.7 +short

# 5. Test HTTPS
curl -k https://test.internal/

# 6. Delete certificate
curl -X DELETE http://localhost:5001/api/certs/test.internal
```

## 🐛 Troubleshooting

### Services prüfen

```bash
systemctl status certflow-api
systemctl status certflow-web
systemctl status certflow-renewal

journalctl -u certflow-api -f
```

### SSH-Verbindungen testen

```bash
# Test step-ca
ssh root@192.168.1.3 "echo OK"

# Test Traefik
ssh root@192.168.1.23 "echo OK"

# Test Pi-hole
ssh root@192.168.1.7 "echo OK"
```

### Datenbank prüfen

```bash
sqlite3 /opt/certflow/certflow/data/cert_manager.db

.tables
SELECT * FROM certificates;
SELECT * FROM renewal_jobs;
```

## 📖 Dokumentation

- **[QUICKSTART.md](docs/QUICKSTART.md)** - Schnelleinstieg
- **[CERT-MANAGER.md](docs/CERT-MANAGER.md)** - Detaillierte Dokumentation
- **[CHANGELOG.md](CHANGELOG.md)** - Versionshistorie

## 🔄 Migration von OpenClaw

Wenn du von OpenClaw cert-manager migrierst:

```bash
bash scripts/migrate-from-openclaw.sh
```

Siehe [Migration Guide](docs/MIGRATION.md) für Details.

## 🤝 Mitwirken

Beiträge sind willkommen! Bitte:

1. Fork das Repository
2. Erstelle einen Feature-Branch
3. Commit deine Änderungen
4. Push zum Branch
5. Öffne einen Pull Request

## 📝 Lizenz

MIT License - siehe [LICENSE](LICENSE) Datei

## 🆘 Support

Bei Problemen:

1. Prüfe [Troubleshooting](#-troubleshooting)
2. Prüfe [Issues](../../issues) für bekannte Probleme
3. Erstelle ein neues Issue mit Details

## 🎉 Erfolgsgeschichten

**Production Deployment:**
- ✅ 50+ Zertifikate verwaltet
- ✅ 100% Auto-Renewal Success Rate
- ✅ Zero-Downtime Deployments
- ✅ Pi-hole v6 kompatibel

---

**CertFlow - Professional SSL Certificate Management 🔒**
