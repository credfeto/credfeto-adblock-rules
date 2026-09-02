#!/bin/bash
# Installs the local adblock-list server on an Arch Linux host with nginx
# pre-installed: creates the sync user and served clone, installs the nginx
# configuration and systemd units, and opens port 80 to private networks when
# firewalld is present. Idempotent - safe to re-run for upgrades (pull this
# checkout first, then re-run).
#
# Privileged artefacts (nginx.conf, systemd units) are deliberately installed
# from THIS checkout, never from the served clone: the clone is writable by
# the unprivileged adblock-sync account, so sourcing root-installed files from
# it would let a compromised sync account feed configuration to root. Only the
# two list files are ever read from the clone (by nginx, as plain content).
set -eu

REPO_URL="https://github.com/credfeto/credfeto-adblock-rules.git"
SYNC_USER="adblock-sync"
DATA_DIR="/var/lib/adblock-rules"
CLONE_DIR="${DATA_DIR}/credfeto-adblock-rules"
NGINX_CONF_TARGET="/etc/nginx/nginx.conf"
UNIT_DIR="/etc/systemd/system"

IPV4_PRIVATE_RANGES=(
    "10.0.0.0/8"
    "172.16.0.0/12"
    "192.168.0.0/16"
)

IPV6_PRIVATE_RANGES=(
    "fc00::/7"
    "fe80::/10"
)

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

allow_ipv4() {
    local subnet="$1"
    local port="$2"
    local protocol="$3"
    firewall-cmd --permanent \
        --add-rich-rule="rule family='ipv4' source address='${subnet}' port port='${port}' protocol='${protocol}' accept"
}

allow_ipv6() {
    local subnet="$1"
    local port="$2"
    local protocol="$3"
    firewall-cmd --permanent \
        --add-rich-rule="rule family='ipv6' source address='${subnet}' port port='${port}' protocol='${protocol}' accept"
}

open_port_for_private_networks() {
    local port="$1"
    local protocol="${2:-tcp}"

    for subnet in "${IPV4_PRIVATE_RANGES[@]}"; do
        allow_ipv4 "${subnet}" "${port}" "${protocol}"
    done

    for subnet in "${IPV6_PRIVATE_RANGES[@]}"; do
        allow_ipv6 "${subnet}" "${port}" "${protocol}"
    done
}

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

[ "$(id -u)" -eq 0 ] || die "This script must be run as root"

for TOOL in nginx git systemctl runuser; do
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
elif [ -f "${UNIT_DIR}/adblock-rules-sync.service" ]; then
    info "Syncing the served clone to origin/main..."
    systemctl start adblock-rules-sync.service
fi

info "Testing the shipped nginx configuration..."
if ! nginx -t -c "${SCRIPT_DIR}/nginx/nginx.conf"; then
    die "nginx configuration test failed - nothing installed"
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

if command -v firewall-cmd >/dev/null 2>&1; then
    info "Opening port 80/tcp to private networks..."
    open_port_for_private_networks 80 tcp
    firewall-cmd --reload
else
    info "firewalld not present - skipping firewall configuration"
fi

success "Install complete: adblock.txt and hosts.txt are served from ${CLONE_DIR}, refreshed hourly by adblock-rules-sync.timer"
