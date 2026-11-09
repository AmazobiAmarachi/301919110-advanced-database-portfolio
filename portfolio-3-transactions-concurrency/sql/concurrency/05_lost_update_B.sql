-- Session B (app server 2): withdraw N5,000 at the same moment (NO lock)
SELECT pg_sleep(0.5);
BEGIN;
SELECT balance AS bal FROM accounts WHERE account_id = 101 \gset
\echo 'B read balance =' :bal
SELECT to_char(clock_timestamp(),'HH24:MI:SS.MS') AS "time", 'B writes bal - 5000' AS step;
UPDATE accounts SET balance = :bal - 5000 WHERE account_id = 101;
COMMIT;
