-- Reset to the un-optimised state (BEFORE measurements)
DROP INDEX IF EXISTS idx_txn_account_created, idx_txn_failed_created, idx_accounts_customer;
ANALYZE;
