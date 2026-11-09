-- Session A: transfer 101 -> 102, locks 101 first then 102
BEGIN;
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 101;
SELECT pg_sleep(1);
SELECT to_char(clock_timestamp(),'HH24:MI:SS.MS') AS "time", 'A now wants row 102' AS step;
UPDATE accounts SET balance = balance + 1000 WHERE account_id = 102;
COMMIT;
