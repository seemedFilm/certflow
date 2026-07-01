#!/usr/bin/env bash
# ============================================================================
# CertFlow Deployment Script
# ============================================================================
# Deployt CertFlow auf einen Remote-Server via SSH
# ============================================================================

set -euo pipefail

# Konfiguration
CERTFLOW_HOST="${CERTFLOW_HOST:-192.168.1.11}"
CERTFLOW_USER="${CERTFLOW_USER:-root}"
INSTALL_PATH="/opt/certflow"
VENV_PATH="${INSTALL_PATH}/venv"

# Farben
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }

echo "========================================"
echo "  CertFlow v2.0.0 Deployment"
echo "========================================"
echo "Target: ${CERTFLOW_USER}@${CERTFLOW_HOST}"
echo "Path:   ${INSTALL_PATH}"
echo ""

# Test SSH-Verbindung
log_info "Teste SSH-Verbindung..."
if ! ssh -o ConnectTimeout=5 "${CERTFLOW_USER}@${CERTFLOW_HOST}" "true" 2>/dev/null; then
    log_error "SSH-Verbindung fehlgeschlagen!"
    echo "Tipp: ssh-copy-id ${CERTFLOW_USER}@${CERTFLOW_HOST}"
    exit 1
fi
log_success "SSH-Verbindung OK"

# Erstelle Verzeichnisse
log_info "Erstelle Verzeichnisse auf Remote-Server..."
ssh "${CERTFLOW_USER}@${CERTFLOW_HOST}" "mkdir -p ${INSTALL_PATH}/{certflow,skills,data,logs}"

# Kopiere Dateien
log_info "Kopiere CertFlow Dateien..."
scp -r certflow/ "${CERTFLOW_USER}@${CERTFLOW_HOST}:${INSTALL_PATH}/"
scp -r skills/ "${CERTFLOW_USER}@${CERTFLOW_HOST}:${INSTALL_PATH}/"
scp requirements.txt "${CERTFLOW_USER}@${CERTFLOW_HOST}:${INSTALL_PATH}/"

# Erstelle Python venv
log_info "Erstelle Python Virtual Environment..."
ssh "${CERTFLOW_USER}@${CERTFLOW_HOST}" << EOF
cd ${INSTALL_PATH}
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -q -r requirements.txt
EOF

log_success "Python Dependencies installiert"

# Initialisiere Datenbank
log_info "Initialisiere Datenbank..."
ssh "${CERTFLOW_USER}@${CERTFLOW_HOST}" << EOF
cd ${INSTALL_PATH}
source venv/bin/activate
python3 certflow/api/init_db.py
EOF

log_success "Datenbank initialisiert"

# Erstelle systemd Services
log_info "Erstelle systemd Services..."

# API Service
ssh "${CERTFLOW_USER}@${CERTFLOW_HOST}" "cat > /etc/systemd/system/certflow-api.service" << EOF
[Unit]
Description=CertFlow API Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_PATH}
ExecStart=${VENV_PATH}/bin/python3 -m uvicorn certflow.api.main:app --host 0.0.0.0 --port 5001
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Web Service
ssh "${CERTFLOW_USER}@${CERTFLOW_HOST}" "cat > /etc/systemd/system/certflow-web.service" << EOF
[Unit]
Description=CertFlow Web Interface
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_PATH}
ExecStart=${VENV_PATH}/bin/python3 certflow/web/app.py
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Renewal Service
ssh "${CERTFLOW_USER}@${CERTFLOW_HOST}" "cat > /etc/systemd/system/certflow-renewal.service" << EOF
[Unit]
Description=CertFlow Auto-Renewal Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_PATH}
ExecStart=${VENV_PATH}/bin/python3 certflow/lib/renewal_scheduler.py
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

log_success "Systemd Services erstellt"

# Reload systemd und starte Services
log_info "Starte CertFlow Services..."
ssh "${CERTFLOW_USER}@${CERTFLOW_HOST}" << 'EOF'
systemctl daemon-reload
systemctl enable certflow-api certflow-web certflow-renewal
systemctl restart certflow-api certflow-web certflow-renewal
sleep 2
systemctl --no-pager status certflow-api certflow-web certflow-renewal
EOF

log_success "Services gestartet"

# Test API
log_info "Teste API..."
sleep 3
if ssh "${CERTFLOW_USER}@${CERTFLOW_HOST}" "curl -sf http://localhost:5001/ > /dev/null"; then
    log_success "API läuft (Port 5001)"
else
    log_error "API antwortet nicht!"
fi

# Test Web-UI
if ssh "${CERTFLOW_USER}@${CERTFLOW_HOST}" "curl -sf http://localhost:5000/ > /dev/null"; then
    log_success "Web-UI läuft (Port 5000)"
else
    log_error "Web-UI antwortet nicht!"
fi

echo ""
echo "========================================"
echo "  🎉 Deployment erfolgreich!"
echo "========================================"
echo ""
echo "Zugriff:"
echo "  Web-UI:  http://${CERTFLOW_HOST}:5000"
echo "  API:     http://${CERTFLOW_HOST}:5001"
echo "  Docs:    http://${CERTFLOW_HOST}:5001/docs"
echo ""
echo "Services:"
echo "  systemctl status certflow-api"
echo "  systemctl status certflow-web"
echo "  systemctl status certflow-renewal"
echo ""
echo "Logs:"
echo "  journalctl -u certflow-api -f"
echo "  journalctl -u certflow-web -f"
echo ""
