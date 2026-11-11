#!/usr/bin/env bash
# Portfolio 5 - High availability: the Lagos primary crashes, Abuja is promoted to primary.
B=/usr/lib/postgresql/16/bin
PRI="psql -h /tmp -p 5433 -U postgres -d paynaija"; REP="psql -h /tmp -p 5434 -U postgres -d paynaija"
pg() { su postgres -c "$*"; }
echo "### BEFORE: last transfer on primary and on replica"
$PRI -c "SELECT max(transfer_id) AS last_transfer_primary FROM transfers;"
$REP -c "SELECT max(transfer_id) AS last_transfer_replica, pg_is_in_recovery() AS is_standby FROM transfers;"
echo "### Lagos primary crashes (immediate shutdown = power failure)"
pg "$B/pg_ctl -D /srv/pg/primary -m immediate stop"
$PRI -c "SELECT 1;" 2>&1 | head -2
echo "### Promote the Abuja standby to be the new primary"
$REP -c "SELECT pg_promote(wait => true) AS promoted;"
$REP -c "SELECT pg_is_in_recovery() AS is_standby;"
echo "### Service continues: a transfer is processed on the NEW primary"
$REP -c "\timing on" -c "CALL transfer_funds(1450, 1451, 2500);"
$REP -c "SELECT transfer_id, from_account, to_account, amount, status, created_at FROM transfers ORDER BY transfer_id DESC LIMIT 1;"
echo "### No committed data was lost"
$REP -c "SELECT (SELECT count(*) FROM customers) customers, (SELECT count(*) FROM transfers) transfers, (SELECT sum(balance) FROM accounts) total_balances;"
