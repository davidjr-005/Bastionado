docker compose exec -T control bash -lc "cinc-auditor exec inspec/target_hardening -t ssh://alumno@10.30.0.20 --password alumno --sudo --sudo-password alumno --no-create-lockfile"
