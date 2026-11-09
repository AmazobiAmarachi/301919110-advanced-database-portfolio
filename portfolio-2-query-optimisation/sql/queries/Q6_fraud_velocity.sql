-- Q6: Fraud check - accounts with 3+ FAILED transactions in the last 30 days
SELECT account_id, count(*) AS failed_attempts, sum(amount) AS attempted_value
FROM transactions
WHERE status = 'FAILED'
  AND created_at >= now() - interval '30 days'
GROUP BY account_id
HAVING count(*) >= 3
ORDER BY failed_attempts DESC;
