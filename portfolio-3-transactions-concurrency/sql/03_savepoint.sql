-- Demo 3: SAVEPOINT - keep the transfer, undo only an optional step that failed
BEGIN;
  UPDATE accounts SET balance = balance - 2000 WHERE account_id = 101;
  UPDATE accounts SET balance = balance + 2000 WHERE account_id = 102;
  SAVEPOINT before_fee;
  -- optional N50 fee posted to a non-existent fee account -> FK error
  INSERT INTO transactions(account_id, txn_type, direction, amount, channel) VALUES (999999,'BILL','CR',50,'APP');
  ROLLBACK TO SAVEPOINT before_fee;
COMMIT;
SELECT account_id, balance FROM accounts WHERE account_id IN (101,102) ORDER BY 1;
