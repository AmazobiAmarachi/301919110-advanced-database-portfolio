-- Q5: Top 3 spenders in each region (CTE + window function)
WITH spend AS (
  SELECT c.customer_id, c.first_name, c.last_name, c.region_id, sum(t.amount) AS spent
  FROM customers c
  JOIN accounts a     ON a.customer_id = c.customer_id
  JOIN transactions t ON t.account_id  = a.account_id
  WHERE t.direction = 'DR' AND t.status = 'SUCCESS'
  GROUP BY c.customer_id
), ranked AS (
  SELECT s.*, rank() OVER (PARTITION BY region_id ORDER BY spent DESC) AS rnk FROM spend s
)
SELECT r.region_name, first_name, last_name, spent, rnk
FROM ranked JOIN regions r USING (region_id)
WHERE rnk <= 3 ORDER BY r.region_name, rnk;
