-- Portfolio 3 - Demo 12: AUDIT account balances and the ledger (double-entry checks)
-- Each query should return ZERO rows / zero difference if the data is consistent.

-- Check 1: every SUCCESSFUL transfer has exactly one DR and one CR of the same amount
SELECT t.transfer_id, t.amount,
       count(*) FILTER (WHERE x.direction='DR') AS debits,
       count(*) FILTER (WHERE x.direction='CR') AS credits
FROM transfers t LEFT JOIN transactions x ON x.transfer_id = t.transfer_id
WHERE t.status = 'SUCCESS'
GROUP BY t.transfer_id, t.amount
HAVING count(*) FILTER (WHERE x.direction='DR') <> 1
    OR count(*) FILTER (WHERE x.direction='CR') <> 1
    OR sum(x.amount) FILTER (WHERE x.direction='DR') <> sum(x.amount) FILTER (WHERE x.direction='CR');

-- Check 2: every REVERSED transfer nets to zero for both accounts (4 ledger rows)
SELECT t.transfer_id,
       sum(CASE WHEN x.direction='CR' THEN x.amount ELSE -x.amount END) AS net_effect
FROM transfers t JOIN transactions x ON x.transfer_id = t.transfer_id
WHERE t.status = 'REVERSED'
GROUP BY t.transfer_id
HAVING sum(CASE WHEN x.direction='CR' THEN x.amount ELSE -x.amount END) <> 0;

-- Check 3: transfers move money, they never create or destroy it
SELECT sum(amount) FILTER (WHERE direction='CR') AS total_credits,
       sum(amount) FILTER (WHERE direction='DR') AS total_debits,
       sum(amount) FILTER (WHERE direction='CR') - sum(amount) FILTER (WHERE direction='DR') AS difference
FROM transactions WHERE txn_type = 'TRANSFER';

-- Check 4: no account is negative or orphaned
SELECT count(*) FILTER (WHERE balance < 0) AS negative_balances,
       count(*) FILTER (WHERE customer_id NOT IN (SELECT customer_id FROM customers)) AS orphan_accounts
FROM accounts;

-- Check 5: audit trail for one account - every balance change is recorded with who/when
SELECT audit_id, action, old_data->>'balance' AS old_balance, new_data->>'balance' AS new_balance,
       changed_by, to_char(changed_at,'YYYY-MM-DD HH24:MI:SS') AS changed_at
FROM audit_log WHERE table_name='accounts' AND record_id = 101
ORDER BY audit_id DESC LIMIT 6;
