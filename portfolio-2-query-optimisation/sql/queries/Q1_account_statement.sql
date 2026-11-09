-- Q1: Account statement - one account's transactions in the last 90 days (most frequent app query)
SELECT txn_id, txn_type, direction, amount, status, channel, created_at
FROM transactions
WHERE account_id = 1450
  AND created_at >= now() - interval '90 days'
ORDER BY created_at DESC;
