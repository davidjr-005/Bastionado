#!/usr/bin/env bash
set -euo pipefail

mkdir -p /var/log/firewall
touch /var/log/firewall/firewall-events.log /var/log/firewall/traffic.log

sysctl -w net.ipv4.ip_forward=1 >/dev/null

/usr/local/bin/firewall-rules.sh "${MITIGATION_MODE:-baseline}"

{
  echo "[$(date -Is)] Firewall iniciado en modo ${MITIGATION_MODE:-baseline}"
  echo "[$(date -Is)] Eventos iptables: /var/log/firewall/firewall-events.log"
  echo "[$(date -Is)] Trafico observado: /var/log/firewall/traffic.log"
} >> /var/log/firewall/firewall-events.log

(dmesg --follow --ctime 2>/var/log/firewall/dmesg.err \
  | grep --line-buffered "P11_" >> /var/log/firewall/firewall-events.log || true) &

(tcpdump -i any -nn -tttt -l "host ${TARGET_IP:-10.12.0.10}" \
  >> /var/log/firewall/traffic.log 2>/var/log/firewall/tcpdump.err || true) &

tail -F /var/log/firewall/firewall-events.log /var/log/firewall/traffic.log
