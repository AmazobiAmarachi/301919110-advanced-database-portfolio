-- Portfolio 2 - Q4 is an analytical (OLAP) query that reads every row: indexes cannot help.
-- Optimisation: pre-compute it once as a materialised view, refreshed nightly.
DROP MATERIALIZED VIEW IF EXISTS mv_monthly_region_debits;
CREATE MATERIALIZED VIEW mv_monthly_region_debits AS
SELECT r.region_name, date_trunc('month', t.created_at) AS month,
       count(*) AS txn_count, sum(t.amount) AS total_value
FROM transactions t
JOIN accounts  a ON a.account_id  = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
JOIN regions   r ON r.region_id   = c.region_id
WHERE t.direction = 'DR' AND t.status = 'SUCCESS'
GROUP BY r.region_name, month;
CREATE UNIQUE INDEX ON mv_monthly_region_debits (region_name, month);
-- Nightly job: REFRESH MATERIALIZED VIEW CONCURRENTLY mv_monthly_region_debits;
