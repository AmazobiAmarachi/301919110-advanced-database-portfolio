-- Portfolio 2 - optimisation: indexes chosen from the BEFORE execution plans
-- 1) Composite B+ tree index: equality on account_id, then range/sort on created_at (Q1, Q2)
CREATE INDEX idx_txn_account_created ON transactions (account_id, created_at DESC);
-- 2) Partial index: only ~3% of rows are FAILED, so a small index serves fraud/report queries (Q3, Q6)
CREATE INDEX idx_txn_failed_created ON transactions (created_at) INCLUDE (account_id, amount, channel)
  WHERE status = 'FAILED';
-- 3) FK index - PostgreSQL does NOT index foreign keys automatically (join customers -> accounts)
CREATE INDEX idx_accounts_customer ON accounts (customer_id);
-- (customers.phone is already indexed by its UNIQUE constraint)
ANALYZE transactions; ANALYZE accounts;
