#!/bin/bash
# Runs once when the primary container is first created
set -e
psql -v ON_ERROR_STOP=1 -U postgres -c "CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replpass';"
echo "host replication replicator all scram-sha-256" >> "$PGDATA/pg_hba.conf"
