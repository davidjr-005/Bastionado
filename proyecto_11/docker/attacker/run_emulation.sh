#!/usr/bin/env bash
set -euo pipefail

TARGET="${TARGET:-10.12.0.10}"

echo "[1/5] Ping sweep controlado contra ${TARGET}"
ping -c 8 "$TARGET" || true

echo "[2/5] Reconocimiento de puertos permitidos y no permitidos"
nmap -Pn -sS -p 22,80,135,139,445,3389,5900 "$TARGET" || true

echo "[3/5] Fuerza bruta SSH simulada con credenciales incorrectas"
for i in $(seq 1 10); do
  sshpass -p "PasswordMala${i}" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    -o ConnectTimeout=2 \
    alumno@"$TARGET" "true" >/dev/null 2>&1 || true
done

echo "[4/5] Rafaga DNS controlada"
for i in $(seq 1 80); do
  dig @"$TARGET" "host${i}.empresa.local" A +tries=1 +time=1 >/dev/null 2>&1 &
done
wait || true

echo "[5/5] Intentos laterales contra servicios no publicados"
for port in 23 135 139 445 3389 5900; do
  nc -vz -w 2 "$TARGET" "$port" || true
done

echo "Emulacion terminada. Revisa logs/firewall/firewall-events.log y logs/firewall/traffic.log"
