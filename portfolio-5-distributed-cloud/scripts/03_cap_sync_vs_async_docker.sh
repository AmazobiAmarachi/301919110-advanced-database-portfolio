#!/usr/bin/env bash
# Portfolio 5 - CAP theorem in practice (Docker version). A network partition is simulated by
# stopping the Abuja replica container, under SYNCHRONOUS vs ASYNCHRONOUS replication.
export PGPASSWORD=paynaija
PRI="psql -h localhost -p 5433 -U postgres -d paynaija"; REP="psql -h localhost -p 5434 -U postgres -d paynaija"

echo "### STEP 1 - switch to SYNCHRONOUS replication (a commit waits until Abuja confirms)"
$PRI -c "ALTER SYSTEM SET synchronous_standby_names = 'abuja_standby';" -c "SELECT pg_reload_conf();" >/dev/null; sleep 2
$PRI -c "SELECT application_name, sync_state FROM pg_stat_replication;"

echo "### STEP 2 - partition: the Abuja replica becomes unreachable"
docker stop paynaija_abuja_replica

echo "### STEP 3 - a customer tries to deposit N5,000 on the Lagos primary"
( $PRI -c "UPDATE accounts SET balance = balance + 5000 WHERE account_id = 300;" > sync_write.txt 2>&1 ) &
sleep 5
echo "after 5 seconds the COMMIT has still not returned - the session is waiting for the standby:"
$PRI -c "SELECT pid, state, wait_event_type, wait_event, now()-query_start AS waiting_for, left(query,60) AS query
         FROM pg_stat_activity WHERE wait_event = 'SyncRep';"
echo "operator cancels the wait:"
$PRI -Atc "SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE wait_event = 'SyncRep';" >/dev/null; sleep 2
cat sync_write.txt; rm -f sync_write.txt
echo "=> CONSISTENCY chosen over AVAILABILITY (CP): the system would rather block than acknowledge"
echo "   a write that exists in only one data centre."

echo "### STEP 4 - switch to ASYNCHRONOUS replication and repeat the write during the partition"
$PRI -c "ALTER SYSTEM SET synchronous_standby_names = '';" -c "SELECT pg_reload_conf();" >/dev/null; sleep 2
$PRI -c "\timing on" -c "UPDATE accounts SET balance = balance + 5000 WHERE account_id = 300;"
echo "=> AVAILABILITY chosen (AP-style): the write succeeds immediately, but if Lagos failed now"
echo "   before Abuja reconnects, this deposit could be lost (eventual consistency)."

echo "### STEP 5 - partition heals: replica restarts and catches up automatically"
docker start paynaija_abuja_replica; sleep 10
$PRI -c "SELECT balance AS primary_balance FROM accounts WHERE account_id = 300;"
$REP -c "SELECT balance AS replica_balance FROM accounts WHERE account_id = 300;"
$PRI -c "SELECT application_name, state, sync_state FROM pg_stat_replication;"
