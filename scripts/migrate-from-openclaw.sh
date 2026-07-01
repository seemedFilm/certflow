#!/usr/bin/env bash
# ============================================================================
# CertFlow Migration Script
# ============================================================================
# Migriert cert-manager von OpenClaw zu standalone CertFlow
# ============================================================================

set -euo pipefail

# Farben
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }

# Konfiguration
OPENCLAW_PATH="/opt/openclaw/skills/cert-manager"
CERTFLOW_PATH="/opt/certflow"
BACKUP_PATH="/root/certflow-migration-backup-$(date +%Y%m%d-%H%M%S)"

echo "========================================"
echo "  CertFlow Migration von OpenClaw"
echo "========================================"
echo ""
echo "OpenClaw Path: ${OPENCLAW_PATH}"
echo "CertFlow Path: ${CERTFLOW_PATH}"
echo "Backup Path:   ${BACKUP_PATH}"
echo ""

# Safety Check
if [[ ! -d "${OPENCLAW_PATH}" ]]; then
    log_error "OpenClaw cert-manager nicht gefunden: ${OPENCLAW_PATH}"
    exit 1
fi

if [[ ! -d "${CERTFLOW_PATH}" ]]; then
    log_error "CertFlow nicht gefunden: ${CERTFLOW_PATH}"
    log_info "Bitte zuerst CertFlow deployen: bash deploy.sh"
    exit 1
fi

# Backup erstellen
log_info "Erstelle Backup..."
mkdir -p "${BACKUP_PATH}"

# Stoppe alte Services
log_info "Stoppe OpenClaw cert-manager Services..."
systemctl stop cert-manager-api cert-manager-web cert-manager-renewal 2>/dev/null || true

# Backup Daten
log_info "Backup Daten..."
if [[ -d "${OPENCLAW_PATH}/data" ]]; then
    cp -r "${OPENCLAW_PATH}/data" "${BACKUP_PATH}/"
    log_success "Datenbank gesichert"
fi

if [[ -d "${OPENCLAW_PATH}/logs" ]]; then
    cp -r "${OPENCLAW_PATH}/logs" "${BACKUP_PATH}/"
    log_success "Logs gesichert"
fi

if [[ -f "${OPENCLAW_PATH}/config/settings.yaml" ]]; then
    cp "${OPENCLAW_PATH}/config/settings.yaml" "${BACKUP_PATH}/"
    log_success "Konfiguration gesichert"
fi

log_success "Backup erstellt: ${BACKUP_PATH}"

# Migriere Daten
log_info "Migriere Daten zu CertFlow..."

if [[ -d "${OPENCLAW_PATH}/data" ]]; then
    cp -r "${OPENCLAW_PATH}/data/"* "${CERTFLOW_PATH}/certflow/data/" 2>/dev/null || true
    log_success "Datenbank migriert"
fi

if [[ -d "${OPENCLAW_PATH}/logs" ]]; then
    cp -r "${OPENCLAW_PATH}/logs/"* "${CERTFLOW_PATH}/certflow/logs/" 2>/dev/null || true
    log_success "Logs migriert"
fi

# Aktualisiere Permissions
chown -R root:root "${CERTFLOW_PATH}/certflow/data"
chown -R root:root "${CERTFLOW_PATH}/certflow/logs"

# Update systemd Services
log_info "Aktualisiere systemd Services..."

# Die Services heißen jetzt certflow-* statt cert-manager-*
if systemctl is-enabled cert-manager-api 2>/dev/null; then
    systemctl disable cert-manager-api
fi
if systemctl is-enabled cert-manager-web 2>/dev/null; then
    systemctl disable cert-manager-web
fi
if systemctl is-enabled cert-manager-renewal 2>/dev/null; then
    systemctl disable cert-manager-renewal
fi

log_success "Alte Services deaktiviert"

# Starte neue CertFlow Services
log_info "Starte CertFlow Services..."
systemctl daemon-reload
systemctl enable certflow-api certflow-web certflow-renewal
systemctl start certflow-api certflow-web certflow-renewal

sleep 3

# Verifiziere Services
if systemctl is-active --quiet certflow-api && \
   systemctl is-active --quiet certflow-web && \
   systemctl is-active --quiet certflow-renewal; then
    log_success "CertFlow Services laufen"
else
    log_error "Services nicht aktiv!"
    systemctl status certflow-*
    exit 1
fi

# Teste API
log_info "Teste CertFlow API..."
if curl -sf http://localhost:5001/ > /dev/null; then
    log_success "API erreichbar (Port 5001)"
else
    log_error "API antwortet nicht!"
fi

# Teste Web-UI
if curl -sf http://localhost:5000/ > /dev/null; then
    log_success "Web-UI erreichbar (Port 5000)"
else
    log_error "Web-UI antwortet nicht!"
fi

# Optional: Cleanup alte Installation
echo ""
log_warning "OpenClaw cert-manager ist noch installiert in: ${OPENCLAW_PATH}"
echo ""
echo "Möchtest du die alte Installation entfernen? (y/N)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    log_info "Entferne alte OpenClaw Installation..."
    rm -rf "${OPENCLAW_PATH}"
    log_success "Alte Installation entfernt"

    # Entferne auch alte systemd Services
    rm -f /etc/systemd/system/cert-manager-*.service
    systemctl daemon-reload
    log_success "Alte systemd Services entfernt"
else
    log_info "Alte Installation bleibt bestehen"
    log_warning "Du kannst sie später manuell entfernen:"
    echo "  rm -rf ${OPENCLAW_PATH}"
    echo "  rm -f /etc/systemd/system/cert-manager-*.service"
fi

echo ""
echo "========================================"
echo "  🎉 Migration erfolgreich!"
echo "========================================"
echo ""
echo "CertFlow läuft nun auf:"
echo "  Web-UI:  http://localhost:5000"
echo "  API:     http://localhost:5001"
echo "  Docs:    http://localhost:5001/docs"
echo ""
echo "Backup gespeichert in:"
echo "  ${BACKUP_PATH}"
echo ""
echo "Services:"
echo "  systemctl status certflow-*"
echo "  journalctl -u certflow-api -f"
echo ""
