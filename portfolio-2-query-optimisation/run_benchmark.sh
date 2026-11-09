#!/usr/bin/env bash
# Runs every query 5x with EXPLAIN (ANALYZE, BUFFERS) and records the median execution time.
# Usage: ./run_benchmark.sh before|after
PHASE=$1; PSQL="psql -h ${PGHOST:-/tmp} -p ${PGPORT:-5433} -U postgres -d paynaija -qAt"
mkdir -p results/plans_$PHASE; : > results/timings_$PHASE.csv
for f in sql/queries/Q*.sql; do
  q=$(basename "$f" .sql); times=()
  for i in 1 2 3 4 5; do
    plan=$( (echo "EXPLAIN (ANALYZE, BUFFERS)"; grep -v '^--' "$f") | $PSQL )
    times+=( $(echo "$plan" | grep 'Execution Time' | awk '{print $3}') )
  done
  echo "$plan" > results/plans_$PHASE/$q.txt
  med=$(printf '%s\n' "${times[@]}" | sort -n | sed -n 3p)
  echo "$q,$med" | tee -a results/timings_$PHASE.csv
done
