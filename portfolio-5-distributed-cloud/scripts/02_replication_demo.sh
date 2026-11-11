#!/usr/bin/env bash
# Portfolio 5 - evidence that replication works
PRI="psql -h /tmp -p 5433 -U postgres -d paynaija -e"; REP="psql -h /tmp -p 5434 -U postgres -d paynaija -e"
echo "### [PRIMARY - Lagos :5433] connected standbys"
$PRI -x -c "SELECT application_name, state, sync_state, sent_lsn, replay_lsn, replay_lag FROM pg_stat_replication;"
echo "### [REPLICA - Abuja :5434] am I a standby?"
$REP -c "SELECT pg_is_in_recovery() AS is_standby, pg_last_wal_replay_lsn() AS replayed_up_to;"
echo "### [PRIMARY] register a new customer + wallet"
$PRI -c "INSERT INTO customers(first_name,last_name,email,phone,date_of_birth,region_id,kyc_tier)
         VALUES ('Royalty','Replica','royalty.replica@mail.ng','+2348090000001','1995-03-15',2,2) RETURNING customer_id, created_at;"
sleep 0.5
echo "### [REPLICA] the same row is already readable on the standby"
$REP -c "SELECT customer_id, first_name, last_name, email, created_at FROM customers WHERE email='royalty.replica@mail.ng';"
echo "### [REPLICA] writes are rejected (read-only hot standby)"
$REP -c "UPDATE accounts SET balance = 0 WHERE account_id = 1;"
echo "### [REPLICA] row counts match the primary"
$PRI -At -c "SELECT 'primary  : '||(SELECT count(*) FROM customers)||' customers, '||(SELECT count(*) FROM transactions)||' transactions'"
$REP -At -c "SELECT 'replica  : '||(SELECT count(*) FROM customers)||' customers, '||(SELECT count(*) FROM transactions)||' transactions'"
echo "### [REPLICA] replication delay"
$REP -c "SELECT now() - pg_last_xact_replay_timestamp() AS replication_delay;"
