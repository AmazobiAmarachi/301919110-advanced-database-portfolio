#!/usr/bin/env bash
# 8 concurrent clients x 40 transfers each, naive vs ordered-locking procedure
B=/usr/lib/postgresql/16/bin; C="-h ${PGHOST:-/tmp} -p ${PGPORT:-5433} -U postgres"
for s in naive_transfer procedure_transfer; do
  psql $C -d paynaija -qc "UPDATE accounts SET balance = 50000 WHERE account_id IN (101,102);"
  echo "===== $s"
  pgbench $C -n -c 8 -j 4 -t 40 --failures-detailed -f sql/stress/$s.pgbench paynaija 2>&1 \
     | grep -E "clients|processed|failed|deadlock|serialization|tps" 
  psql $C -d paynaija -c "SELECT sum(balance) AS total_money_101_plus_102 FROM accounts WHERE account_id IN (101,102);"
done
