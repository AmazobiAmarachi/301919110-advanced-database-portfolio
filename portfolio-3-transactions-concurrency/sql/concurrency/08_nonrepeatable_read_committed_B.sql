-- Session B: commits a N1,000 withdrawal between A's two reads
SELECT pg_sleep(0.5);
UPDATE accounts SET balance = balance - 1000 WHERE account_id = 101;
SELECT to_char(clock_timestamp(),'HH24:MI:SS.MS') AS "time", 'B committed -1000' AS step;
