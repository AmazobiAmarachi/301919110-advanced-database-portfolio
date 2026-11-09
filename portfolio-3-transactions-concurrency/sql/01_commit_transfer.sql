-- Demo 1: a successful transfer of N10,000 from account 101 to 102 (ATOMICITY + DURABILITY)
BEGIN;
  INSERT INTO transfers(from_account, to_account, amount, status)
  VALUES (101, 102, 10000, 'SUCCESS') RETURNING transfer_id AS tid \gset
  UPDATE accounts SET balance = balance - 10000 WHERE account_id = 101;
  UPDATE accounts SET balance = balance + 10000 WHERE account_id = 102;
  INSERT INTO transactions(account_id, txn_type, direction, amount, transfer_id, channel)
  VALUES (101,'TRANSFER','DR',10000,:tid,'APP'), (102,'TRANSFER','CR',10000,:tid,'APP');
COMMIT;
SELECT account_id, balance FROM accounts WHERE account_id IN (101,102) ORDER BY 1;
SELECT audit_id, record_id, old_data, new_data FROM audit_log ORDER BY audit_id DESC LIMIT 2;
