-- Portfolio 3 - reset two demo accounts to known balances before each demo
UPDATE accounts SET balance = 50000.00, status='ACTIVE' WHERE account_id IN (101, 102);
SELECT account_id, account_number, balance FROM accounts WHERE account_id IN (101,102) ORDER BY 1;
