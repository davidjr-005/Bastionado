#!/usr/bin/env bash
set -euo pipefail

ip route replace 10.11.0.0/24 via 10.12.0.2 || true

cat >/etc/dnsmasq.d/proyecto11.conf <<'EOF'
interface=eth0
listen-address=10.12.0.10
bind-interfaces
address=/empresa.local/10.12.0.10
log-queries
log-facility=/var/log/dnsmasq.log
EOF

service ssh start
service nginx start
service dnsmasq restart

tail -F /var/log/auth.log /var/log/nginx/access.log /var/log/dnsmasq.log
