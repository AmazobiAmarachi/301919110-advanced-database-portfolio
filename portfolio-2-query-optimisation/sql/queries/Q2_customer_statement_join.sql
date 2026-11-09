-- Q2: Customer statement with JOINs - all wallet transactions for one customer (by phone number)
SELECT c.first_name, c.last_name, a.account_number, t.txn_type, t.amount, t.created_at
FROM customers c
JOIN accounts a     ON a.customer_id = c.customer_id
JOIN transactions t ON t.account_id  = a.account_id
WHERE c.phone = '+2347000001234'
ORDER BY t.created_at DESC;
