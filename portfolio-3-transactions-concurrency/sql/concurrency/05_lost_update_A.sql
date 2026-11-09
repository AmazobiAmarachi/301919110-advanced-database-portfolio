-- Session A (app server 1): withdraw N10,000 using read-then-write logic (NO lock)
BEGIN;
SELECT balance AS bal FROM accounts WHERE account_id = 101 \gset
\echo 'A read balance =' :bal
SELECT pg_sleep(2);   -- app does other work (fraud checks, network call...)
SELECT to_char(clock_timestamp(),'HH24:MI:SS.MS') AS "time", 'A writes bal - 10000' AS step;
UPDATE accounts SET balance = :bal - 10000 WHERE account_id = 101;
COMMIT;
