-- Demo 2: transfer of N100,000 when account 101 only has N40,000.
-- The debit violates CHECK (balance >= 0); the whole transaction is rolled back (ATOMICITY + CONSISTENCY)
SELECT account_id, balance FROM accounts WHERE account_id IN (101,102) ORDER BY 1;
BEGIN;
  UPDATE accounts SET balance = balance + 100000 WHERE account_id = 102;   -- credit succeeds...
  UPDATE accounts SET balance = balance - 100000 WHERE account_id = 101;   -- ...debit FAILS
COMMIT;   -- PostgreSQL turns this into ROLLBACK because the transaction is in an aborted state
SELECT account_id, balance FROM accounts WHERE account_id IN (101,102) ORDER BY 1;  -- unchanged
