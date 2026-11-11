#!/usr/bin/env bash
# Portfolio 5 - evidence that replication works (Docker version: Lagos primary :5433, Abuja replica :5434)
export PGPASSWORD=paynaija
PRI="psql -h localhost -p 5433 -U postgres -d paynaija -e"; REP="psql -h localhost -p 5434 -U postgres -d paynaija -e"
echo "### [PRIMARY - Lagos :5433] connected standbys"
$PRI -x -c "SELECT application_name, state, sync_state, sent_lsn, replay_lsn, replay_lag FROM pg_stat_replication;"
echo "### [REPLICA - Abuja :5434] am I a standby?"
$REP -c "SELECT pg_is_in_recovery() AS is_standby, pg_last_wal_replay_lsn() AS replayed_up_to;"
echo "### [PRIMARY] register a new customer"
$PRI -c "INSERT INTO customers(first_name,last_name,email,phone,date_of_birth,region_id,kyc_tier)
         VALUES ('Ada','Replica','ada.replica@mail.ng','+2348090000001','1995-03-15',2,2) RETURNING customer_id, created_at;"
sleep 1
echo "### [REPLICA] the same row is already readable on the standby"
$REP -c "SELECT customer_id, first_name, last_name, email, created_at FROM customers WHERE email='ada.replica@mail.ng';"
echo "### [REPLICA] writes are rejected (read-only hot standby)"
$REP -c "UPDATE accounts SET balance = 0 WHERE account_id = 1;"
echo "### Row counts match on both sites"
psql -h localhost -p 5433 -U postgres -d paynaija -At -c "SELECT 'primary  : '||(SELECT count(*) FROM customers)||' customers, '||(SELECT count(*) FROM transactions)||' transactions'"
psql -h localhost -p 5434 -U postgres -d paynaija -At -c "SELECT 'replica  : '||(SELECT count(*) FROM customers)||' customers, '||(SELECT count(*) FROM transactions)||' transactions'"
echo "### [REPLICA] replication delay"
$REP -c "SELECT now() - pg_last_xact_replay_timestamp() AS replication_delay;"
