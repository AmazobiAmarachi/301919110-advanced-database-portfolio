-- Q4: Management report - monthly debit value per region (aggregation over 3 joined tables)
SELECT r.region_name, date_trunc('month', t.created_at) AS month,
       count(*) AS txn_count, sum(t.amount) AS total_value
FROM transactions t
JOIN accounts  a ON a.account_id  = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
JOIN regions   r ON r.region_id   = c.region_id
WHERE t.direction = 'DR' AND t.status = 'SUCCESS'
GROUP BY r.region_name, month
ORDER BY month, total_value DESC;
