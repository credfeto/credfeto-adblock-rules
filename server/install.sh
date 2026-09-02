#!/bin/sh
# Installs the local adblock-list server on an Arch Linux host with nginx
# pre-installed: creates the sync user and clone, tests and installs the
# nginx configuration, and enables the hourly repo sync timer.
# Idempotent - safe to re-run for upgrades.
set -eu

REPO_URL="https://github.com/credfeto/credfeto-adblock-rules.git"
SYNC_USER="adblock-sync"
DATA_DIR="/var/lib/adblock-rules"
CLONE_DIR="${DATA_DIR}/credfeto-adblock-rules"
NGINX_CONF_TARGET="/etc/nginx/nginx.conf"
UNIT_DIR="/etc/systemd/system"

die() {
    if [ -t 2 ]; then
        printf '\n\033[31m✗\033[0m %s\n' "$*" >&2
    else
        printf '\n✗ %s\n' "$*" >&2
    fi
    exit 1
}

success() {
    if [ -t 1 ]; then
        printf '\n\033[32m✓\033[0m %s\n' "$*"
    else
        printf '\n✓ %s\n' "$*"
    fi
}

info() {
    if [ -t 1 ]; then
        printf '\n\033[32m→\033[0m %s\n' "$*"
    else
        printf '\n→ %s\n' "$*"
    fi
}

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

[ "$(id -u)" -eq 0 ] || die "This script must be run as root"

for TOOL in nginx git systemctl runuser install; do
    command -v "${TOOL}" >/dev/null 2>&1 || die "Required tool '${TOOL}' is not installed"
done

info "Ensuring the ${SYNC_USER} system user exists..."
if ! id -u "${SYNC_USER}" >/dev/null 2>&1; then
    useradd --system --home-dir "${DATA_DIR}" --create-home --shell /usr/bin/nologin "${SYNC_USER}"
fi
mkdir -p "${DATA_DIR}"
chown "${SYNC_USER}:${SYNC_USER}" "${DATA_DIR}"
chmod 755 "${DATA_DIR}"

if [ ! -d "${CLONE_DIR}/.git" ]; then
    info "Cloning ${REPO_URL} into ${CLONE_DIR}..."
    runuser -u "${SYNC_USER}" -- git clone "${REPO_URL}" "${CLONE_DIR}"
else
    info "Clone already present - syncing to origin/main..."
    runuser -u "${SYNC_USER}" -- git -C "${CLONE_DIR}" fetch origin main
    runuser -u "${SYNC_USER}" -- git -C "${CLONE_DIR}" reset --hard origin/main
fi

info "Testing the shipped nginx configuration..."
if ! nginx -t -c "${SCRIPT_DIR}/nginx/nginx.conf"; then
    die "nginx configuration test failed - existing configuration left untouched"
fi

if [ -f "${NGINX_CONF_TARGET}" ] && ! cmp -s "${SCRIPT_DIR}/nginx/nginx.conf" "${NGINX_CONF_TARGET}"; then
    BACKUP="${NGINX_CONF_TARGET}.bak.$(date +%Y%m%d%H%M%S)"
    info "Backing up existing configuration to ${BACKUP}..."
    cp -p "${NGINX_CONF_TARGET}" "${BACKUP}"
fi

info "Installing nginx configuration..."
install -m 0644 "${SCRIPT_DIR}/nginx/nginx.conf" "${NGINX_CONF_TARGET}"
systemctl enable nginx
systemctl reload-or-restart nginx

info "Installing systemd sync units..."
install -m 0644 "${SCRIPT_DIR}/adblock-rules-sync.service" "${UNIT_DIR}/adblock-rules-sync.service"
install -m 0644 "${SCRIPT_DIR}/adblock-rules-sync.timer" "${UNIT_DIR}/adblock-rules-sync.timer"
systemctl daemon-reload
systemctl enable --now adblock-rules-sync.timer

success "Install complete: http://abp.markridgwell.com/adblock.txt and /hosts.txt are served from ${CLONE_DIR}, refreshed hourly by adblock-rules-sync.timer"
