-- Q3 (BEFORE rewrite): failed transactions on a given day - function applied to the column
SELECT txn_id, account_id, amount, channel
FROM transactions
WHERE status = 'FAILED'
  AND created_at::date = (CURRENT_DATE - 7);
