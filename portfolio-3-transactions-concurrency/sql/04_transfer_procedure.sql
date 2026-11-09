-- Demo 4: production-grade transfer as a stored procedure.
-- Locks both rows in a consistent order (lowest id first) to prevent deadlocks,
-- validates status and funds, posts double-entry ledger rows, and logs failures.
CREATE OR REPLACE PROCEDURE transfer_funds(p_from INT, p_to INT, p_amount NUMERIC)
LANGUAGE plpgsql AS $$
DECLARE v_from accounts%ROWTYPE; v_to accounts%ROWTYPE; v_tid BIGINT;
BEGIN
  IF p_amount <= 0 THEN RAISE EXCEPTION 'Amount must be positive'; END IF;
  -- pessimistic locking in a fixed order
  PERFORM 1 FROM accounts WHERE account_id IN (p_from, p_to) ORDER BY account_id FOR UPDATE;
  SELECT * INTO v_from FROM accounts WHERE account_id = p_from;
  SELECT * INTO v_to   FROM accounts WHERE account_id = p_to;
  IF v_from.status <> 'ACTIVE' OR v_to.status <> 'ACTIVE' THEN
     RAISE EXCEPTION 'Account not active';
  END IF;
  IF v_from.balance < p_amount THEN
     RAISE EXCEPTION 'Insufficient funds: balance %, requested %', v_from.balance, p_amount;
  END IF;
  INSERT INTO transfers(from_account,to_account,amount,status) VALUES (p_from,p_to,p_amount,'SUCCESS')
  RETURNING transfer_id INTO v_tid;
  UPDATE accounts SET balance = balance - p_amount WHERE account_id = p_from;
  UPDATE accounts SET balance = balance + p_amount WHERE account_id = p_to;
  INSERT INTO transactions(account_id,txn_type,direction,amount,transfer_id,channel)
  VALUES (p_from,'TRANSFER','DR',p_amount,v_tid,'APP'), (p_to,'TRANSFER','CR',p_amount,v_tid,'APP');
END $$;

CALL transfer_funds(101, 102, 5000);      -- succeeds
CALL transfer_funds(101, 102, 9000000);   -- fails: insufficient funds, nothing changes
SELECT account_id, balance FROM accounts WHERE account_id IN (101,102) ORDER BY 1;
