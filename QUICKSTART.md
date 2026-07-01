# CertFlow Quick Start

Schnelleinstieg für CertFlow SSL Certificate Management.

## Voraussetzungen

- **step-ca Server** (192.168.1.3)
- **Traefik Server** (192.168.1.23)
- **Pi-hole Server** (192.168.1.7)
- **CertFlow Host** (z.B. 192.168.1.11)
- SSH-Keys zu allen Servern eingerichtet

## Installation (5 Minuten)

### 1. Repository clonen

```bash
cd /opt
git clone https://github.com/yourusername/certflow.git
cd certflow
```

### 2. Konfiguration anpassen

```bash
nano certflow/config/settings.yaml
```

Wichtige Einstellungen:
```yaml
certificate:
  step_ca:
    host: "192.168.1.3"      # Dein step-ca Server
    ssh_key: "/root/.ssh/id_ed25519"

traefik:
  host: "192.168.1.23"       # Dein Traefik Server
```

Pi-hole konfigurieren:
```bash
nano skills/pihole-dns-manager/config.yaml
```

```yaml
pihole:
  host: "192.168.1.7"        # Dein Pi-hole Server
  traefik_ip: "192.168.1.23" # Traefik IP für DNS A-Records
```

### 3. Deployment

```bash
# Lokal deployen (auf diesem Server)
export CERTFLOW_HOST="localhost"
bash deploy.sh

# ODER: Remote deployen
export CERTFLOW_HOST="192.168.1.11"
bash deploy.sh
```

### 4. Zugriff

**Web-Interface:**
```
http://192.168.1.11:5000
```

**API Dokumentation:**
```
http://192.168.1.11:5001/docs
```

## Erstes Zertifikat erstellen

### Via Web-UI

1. Öffne http://192.168.1.11:5000
2. Klicke "Neues Zertifikat"
3. Eingeben:
   - Hostname: `myapp.internal`
   - Backend-IP: `https://192.168.1.50:8080`
   - Haken bei "Traefik Config erstellen"
   - Haken bei "Auto-Renewal"
4. Klicke "Erstellen"

### Via API

```bash
curl -X POST http://192.168.1.11:5001/api/certs \
  -H "Content-Type: application/json" \
  -d '{
    "hostname": "myapp.internal",
    "type": "step-ca",
    "create_traefik_config": true,
    "backend_ip": "https://192.168.1.50:8080",
    "auto_renew": true
  }'
```

## Testen

### 1. Zertifikat prüfen

```bash
# Auf step-ca Server
ssh root@192.168.1.3 "ls -la /srv/pki/myapp/"
```

### 2. Traefik Config prüfen

```bash
ssh root@192.168.1.23 "cat /docker/volume/traefik/dynamic/myapp.yml"
```

### 3. DNS prüfen

```bash
dig myapp.internal @192.168.1.7 +short
# Sollte 192.168.1.23 zurückgeben
```

### 4. HTTPS-Zugriff testen

```bash
curl -k https://myapp.internal/
```

## Services verwalten

### Status prüfen

```bash
ssh root@192.168.1.11 "systemctl status certflow-api certflow-web certflow-renewal"
```

### Logs ansehen

```bash
# API Logs
ssh root@192.168.1.11 "journalctl -u certflow-api -f"

# Web-UI Logs
ssh root@192.168.1.11 "journalctl -u certflow-web -f"
```

### Services neustarten

```bash
ssh root@192.168.1.11 "systemctl restart certflow-api certflow-web certflow-renewal"
```

## Troubleshooting

### Services laufen nicht

```bash
# Prüfe Service-Status
systemctl status certflow-*

# Prüfe Logs
journalctl -u certflow-api -n 50
```

### SSH-Fehler

```bash
# Teste SSH-Verbindungen
ssh root@192.168.1.3 "echo step-ca OK"
ssh root@192.168.1.23 "echo traefik OK"
ssh root@192.168.1.7 "echo pihole OK"
```

### Python-Fehler

```bash
# Prüfe Python venv
cd /opt/certflow
source venv/bin/activate
python3 -c "import fastapi; import flask; print('OK')"
```

### Datenbank-Fehler

```bash
# Datenbank neu initialisieren
cd /opt/certflow
source venv/bin/activate
python3 certflow/api/init_db.py
```

## Nächste Schritte

- **[README.md](README.md)** - Vollständige Dokumentation
- **[docs/CERT-MANAGER.md](docs/CERT-MANAGER.md)** - Detaillierte Funktionen
- **API Docs** - http://192.168.1.11:5001/docs

## Support

Bei Problemen:
1. Prüfe Logs: `journalctl -u certflow-api -f`
2. Prüfe [Issues](https://github.com/yourusername/certflow/issues)
3. Erstelle neues Issue mit Details

---

**CertFlow v2.0.0** 🔒
