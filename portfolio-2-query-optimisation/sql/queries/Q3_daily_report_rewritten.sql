-- Q3 (AFTER rewrite): same result, but a sargable range predicate so an index can be used
SELECT txn_id, account_id, amount, channel
FROM transactions
WHERE status = 'FAILED'
  AND created_at >= (CURRENT_DATE - 7)
  AND created_at <  (CURRENT_DATE - 6);
