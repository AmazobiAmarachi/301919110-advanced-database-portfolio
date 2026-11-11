-- Portfolio 3 - Demo 11: REVERSE a completed transfer (customer dispute / wrong recipient)
-- A committed transaction can never be "un-committed" (Durability), so a reversal is a NEW
-- compensating transaction that moves the money back and keeps the full history.
CREATE OR REPLACE PROCEDURE reverse_transfer(p_transfer_id BIGINT, p_reason TEXT)
LANGUAGE plpgsql AS $$
DECLARE t transfers%ROWTYPE; v_bal NUMERIC;
BEGIN
  SELECT * INTO t FROM transfers WHERE transfer_id = p_transfer_id FOR UPDATE;   -- lock the transfer row
  IF NOT FOUND THEN RAISE EXCEPTION 'Transfer % does not exist', p_transfer_id; END IF;
  IF t.status <> 'SUCCESS' THEN
     RAISE EXCEPTION 'Transfer % cannot be reversed (status %)', p_transfer_id, t.status;
  END IF;
  -- lock both accounts in ascending id order (same deadlock-prevention rule as transfer_funds)
  PERFORM 1 FROM accounts WHERE account_id IN (t.from_account, t.to_account) ORDER BY account_id FOR UPDATE;
  SELECT balance INTO v_bal FROM accounts WHERE account_id = t.to_account;
  IF v_bal < t.amount THEN
     RAISE EXCEPTION 'Recipient has already spent the funds (balance %, needed %)', v_bal, t.amount;
  END IF;
  UPDATE accounts SET balance = balance - t.amount WHERE account_id = t.to_account;
  UPDATE accounts SET balance = balance + t.amount WHERE account_id = t.from_account;
  INSERT INTO transactions(account_id, txn_type, direction, amount, transfer_id, channel)
  VALUES (t.to_account,   'TRANSFER', 'DR', t.amount, t.transfer_id, 'WEB'),
         (t.from_account, 'TRANSFER', 'CR', t.amount, t.transfer_id, 'WEB');
  UPDATE transfers SET status = 'REVERSED' WHERE transfer_id = p_transfer_id;
  INSERT INTO audit_log(table_name, record_id, action, new_data)
  VALUES ('transfers', p_transfer_id, 'REVERSE', jsonb_build_object('reason', p_reason, 'amount', t.amount));
END $$;

-- Demo: send N7,500 from 101 to 102, then reverse it
UPDATE accounts SET balance = 50000 WHERE account_id IN (101, 102);
CALL transfer_funds(101, 102, 7500);
SELECT max(transfer_id) AS tid FROM transfers \gset
SELECT account_id, balance FROM accounts WHERE account_id IN (101,102) ORDER BY 1;   -- 42500 / 57500
CALL reverse_transfer(:tid, 'Customer sent to wrong account');
SELECT account_id, balance FROM accounts WHERE account_id IN (101,102) ORDER BY 1;   -- back to 50000 / 50000
SELECT transfer_id, from_account, to_account, amount, status FROM transfers WHERE transfer_id = :tid;
SELECT account_id, direction, amount FROM transactions WHERE transfer_id = :tid ORDER BY txn_id;  -- 4 ledger rows
-- Safety checks (both expected to FAIL)
CALL reverse_transfer(:tid, 'second attempt');            -- already REVERSED
CALL reverse_transfer(99999999, 'does not exist');        -- unknown transfer
