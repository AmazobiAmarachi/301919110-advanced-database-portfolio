-- Session A: reads the same balance twice inside one transaction (READ COMMITTED)
BEGIN ISOLATION LEVEL READ COMMITTED;
SELECT 'first read' AS read, balance FROM accounts WHERE account_id = 101;
SELECT pg_sleep(2);
SELECT 'second read' AS read, balance FROM accounts WHERE account_id = 101;
COMMIT;
