#!/usr/bin/env bash
# Portfolio 5 - PostgreSQL 16 streaming replication: Primary (port 5433) -> Replica (port 5434)
# Simulates two data centres for PayNaija: Lagos (primary) and Abuja (hot standby).
set -e
B=/usr/lib/postgresql/16/bin
# 1. Take a physical base backup of the running primary; -R writes standby.signal + primary_conninfo
sudo -u postgres $B/pg_basebackup -h /tmp -p 5433 -U postgres -D /srv/pg/replica \
     -R -X stream -c fast -P --label="abuja-standby"
# 2. Name the standby so the primary can identify it
echo "primary_conninfo = 'host=/tmp port=5433 user=postgres application_name=abuja_standby'" \
     | sudo -u postgres tee -a /srv/pg/replica/postgresql.auto.conf
# 3. Start the replica as a read-only hot standby on port 5434
sudo -u postgres $B/pg_ctl -D /srv/pg/replica -o "-p 5434 -k /tmp" -l /srv/pg/replica.log start
