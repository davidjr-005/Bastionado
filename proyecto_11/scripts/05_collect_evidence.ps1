$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
New-Item -ItemType Directory -Force evidencias | Out-Null

docker compose ps | Out-File -Encoding utf8 "evidencias/${stamp}_docker-compose-ps.txt"
docker compose exec -T firewall bash -lc "iptables -L FORWARD -n -v --line-numbers" | Out-File -Encoding utf8 "evidencias/${stamp}_firewall-counters.txt"
docker compose exec -T firewall bash -lc "tail -n 200 /var/log/firewall/firewall-events.log" | Out-File -Encoding utf8 "evidencias/${stamp}_firewall-events-tail.txt"
docker compose exec -T firewall bash -lc "tail -n 200 /var/log/firewall/traffic.log" | Out-File -Encoding utf8 "evidencias/${stamp}_firewall-traffic-tail.txt"
docker compose exec -T target bash -lc "tail -n 100 /var/log/auth.log || true" | Out-File -Encoding utf8 "evidencias/${stamp}_target-auth-tail.txt"
docker compose exec -T target bash -lc "ss -tulpen && printf '\n--- sshd_config relevante ---\n' && grep -E '^(PermitRootLogin|MaxAuthTries|X11Forwarding|Banner)' /etc/ssh/sshd_config" | Out-File -Encoding utf8 "evidencias/${stamp}_target-hardening.txt"
docker compose exec -T target bash -lc "printf '%s\n' '--- nginx access ---' && tail -n 80 /var/log/nginx/access.log 2>/dev/null || true; printf '%s\n' '--- dnsmasq ---'; tail -n 80 /var/log/dnsmasq.log 2>/dev/null || true" | Out-File -Encoding utf8 "evidencias/${stamp}_target-services-tail.txt"

Write-Host "Evidencias exportadas en la carpeta evidencias con marca ${stamp}"
