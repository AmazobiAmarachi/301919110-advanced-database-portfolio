-- Portfolio 2 - the cost of indexes: time to insert 50,000 rows WITH vs WITHOUT the extra indexes.
-- Each test runs inside a transaction that is rolled back, so the data is unchanged.
\timing on
\echo '--- WITH indexes'
BEGIN;
INSERT INTO transactions(account_id, txn_type, direction, amount, channel)
SELECT 1 + (g % 2987), 'AIRTIME', 'DR', 500, 'USSD' FROM generate_series(1,50000) g;
ROLLBACK;
\echo '--- WITHOUT indexes (dropped inside the transaction)'
BEGIN;
DROP INDEX idx_txn_account_created, idx_txn_failed_created;
INSERT INTO transactions(account_id, txn_type, direction, amount, channel)
SELECT 1 + (g % 2987), 'AIRTIME', 'DR', 500, 'USSD' FROM generate_series(1,50000) g;
ROLLBACK;
