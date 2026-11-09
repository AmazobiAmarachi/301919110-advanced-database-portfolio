-- Session A: withdraw N10,000 and hold the transaction open for 2 s
BEGIN;
UPDATE accounts SET balance = balance - 10000 WHERE account_id = 101;
SELECT pg_sleep(2);
SELECT to_char(clock_timestamp(),'HH24:MI:SS.MS') AS "time", 'A commits' AS step;
COMMIT;
