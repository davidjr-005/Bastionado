docker compose exec -T attacker bash -lc "/opt/emulation/run_emulation.sh"

docker compose exec -T target bash -lc "for i in \$(seq 1 8); do curl -m 2 http://10.11.0.10:4444/beacon-\$i >/dev/null 2>&1 || true; sleep 1; done"
