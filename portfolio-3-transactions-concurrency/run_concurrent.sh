#!/usr/bin/env bash
# Runs Session A and Session B scripts at the same time (two separate connections)
# Usage: ./run_concurrent.sh 05_lost_update
D=$1; PSQL="psql -h ${PGHOST:-/tmp} -p ${PGPORT:-5433} -U postgres -d paynaija -e"
mkdir -p results
$PSQL -q -c "UPDATE accounts SET balance = 50000 WHERE account_id IN (101,102);" >/dev/null
$PSQL -f sql/concurrency/${D}_A.sql > results/${D}_sessionA.txt 2>&1 &
$PSQL -f sql/concurrency/${D}_B.sql > results/${D}_sessionB.txt 2>&1 &
wait
$PSQL -c "SELECT account_id, balance AS final_balance FROM accounts WHERE account_id IN (101,102) ORDER BY 1;" > results/${D}_final.txt
