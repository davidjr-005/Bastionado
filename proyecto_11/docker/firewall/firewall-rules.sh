#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-baseline}"
TARGET_IP="${TARGET_IP:-10.12.0.10}"
ATTACKER_NET="${ATTACKER_NET:-10.11.0.0/24}"
DMZ_NET="${DMZ_NET:-10.12.0.0/24}"

iptables -F
iptables -t nat -F
iptables -X || true

iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A FORWARD -m conntrack --ctstate INVALID \
  -m limit --limit 6/min -j LOG --log-prefix "P11_DROP_INVALID " --log-level 4
iptables -A FORWARD -m conntrack --ctstate INVALID -j DROP

# Reconocimiento clasico contra servicios que no deben estar expuestos.
iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p tcp \
  -m multiport --dports 23,135,139,445,3389,5900 \
  -m limit --limit 18/min -j LOG --log-prefix "P11_DROP_RECON " --log-level 4
iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p tcp \
  -m multiport --dports 23,135,139,445,3389,5900 -j DROP

if [ "$MODE" = "strict" ]; then
  # Mitigacion: limitar fuerza bruta SSH por origen.
  iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p tcp --dport 22 \
    -m conntrack --ctstate NEW -m recent --name P11_SSH --update --seconds 60 --hitcount 5 \
    -m limit --limit 12/min -j LOG --log-prefix "P11_DROP_SSH_BRUTE " --log-level 4
  iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p tcp --dport 22 \
    -m conntrack --ctstate NEW -m recent --name P11_SSH --update --seconds 60 --hitcount 5 -j DROP
  iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p tcp --dport 22 \
    -m conntrack --ctstate NEW -m recent --name P11_SSH --set -j ACCEPT

  # Mitigacion: limitar rafagas DNS hacia el servidor.
  iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p udp --dport 53 \
    -m hashlimit --hashlimit-name P11_DNS --hashlimit-mode srcip \
    --hashlimit-above 15/second --hashlimit-burst 30 \
    -m limit --limit 12/min -j LOG --log-prefix "P11_DROP_DNS_FLOOD " --log-level 4
  iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p udp --dport 53 \
    -m hashlimit --hashlimit-name P11_DNS --hashlimit-mode srcip \
    --hashlimit-above 15/second --hashlimit-burst 30 -j DROP

  # Mitigacion: limitar barridos ICMP.
  iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p icmp \
    -m limit --limit 8/second --limit-burst 12 -j ACCEPT
  iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p icmp \
    -m limit --limit 12/min -j LOG --log-prefix "P11_DROP_ICMP_FLOOD " --log-level 4
  iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p icmp -j DROP

  # Mitigacion: bloquear beacons de C2 simulados desde DMZ hacia la red atacante.
  iptables -A FORWARD -s "$DMZ_NET" -d "$ATTACKER_NET" -p tcp --dport 4444 \
    -m limit --limit 12/min -j LOG --log-prefix "P11_DROP_C2_BEACON " --log-level 4
  iptables -A FORWARD -s "$DMZ_NET" -d "$ATTACKER_NET" -p tcp --dport 4444 -j DROP
else
  # Modo base: permite servicios del laboratorio para observar actividad antes de mitigar.
  iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p icmp -j ACCEPT
fi

iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p tcp -m multiport --dports 22,80 -j ACCEPT
iptables -A FORWARD -s "$ATTACKER_NET" -d "$TARGET_IP" -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -s "$DMZ_NET" -d "$ATTACKER_NET" -p tcp --dport 4444 -j ACCEPT

iptables -A FORWARD -m limit --limit 20/min -j LOG --log-prefix "P11_DROP_DEFAULT " --log-level 4
iptables -A FORWARD -j DROP

iptables-save > "/var/log/firewall/iptables-${MODE}.rules"
echo "[$(date -Is)] Reglas aplicadas: ${MODE}" >> /var/log/firewall/firewall-events.log
