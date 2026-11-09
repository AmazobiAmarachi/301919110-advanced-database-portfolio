-- Session B: transfer 102 -> 101, locks 102 first then 101 (opposite order)
SELECT pg_sleep(0.3);
BEGIN;
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 102;
SELECT pg_sleep(1);
SELECT to_char(clock_timestamp(),'HH24:MI:SS.MS') AS "time", 'B now wants row 101' AS step;
UPDATE accounts SET balance = balance + 1000 WHERE account_id = 101;
COMMIT;
