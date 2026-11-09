-- Session B: REPEATABLE READ transaction tries to update the same row
SELECT pg_sleep(0.5);
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT balance FROM accounts WHERE account_id = 101;   -- snapshot taken here
SELECT to_char(clock_timestamp(),'HH24:MI:SS.MS') AS "time", 'B tries to update (blocks until A finishes)' AS step;
UPDATE accounts SET balance = balance - 5000 WHERE account_id = 101;
ROLLBACK;
\echo 'B: application catches SQLSTATE 40001 and RETRIES the whole transaction:'
BEGIN ISOLATION LEVEL REPEATABLE READ;
UPDATE accounts SET balance = balance - 5000 WHERE account_id = 101;
COMMIT;
