-- Q4b: same report served from the materialised view
SELECT region_name, month, txn_count, total_value
FROM mv_monthly_region_debits
ORDER BY month, total_value DESC;
