-- =====================================================================
-- MIT 8103 Advanced Database Systems - Portfolio 1
-- Case study : PayNaija Wallet (simulated Nigerian digital wallet / fintech)
-- DBMS       : PostgreSQL 16
-- File       : 01_schema.sql  - creates the normalised (3NF) relational schema
-- Run        : psql -d paynaija -f 01_schema.sql
-- =====================================================================

DROP TABLE IF EXISTS audit_log, transactions, transfers, cards, accounts,
                     kyc_documents, merchants, customers, staff, regions CASCADE;

-- Lookup: operating regions (used later for horizontal fragmentation/sharding)
CREATE TABLE regions (
    region_id   SMALLSERIAL PRIMARY KEY,
    region_name VARCHAR(40) NOT NULL UNIQUE,          -- e.g. 'Lagos'
    zone        VARCHAR(20) NOT NULL
                CHECK (zone IN ('South-West','South-South','South-East',
                                'North-Central','North-West','North-East'))
);

-- Internal users of the database (support, compliance, admins)
CREATE TABLE staff (
    staff_id   SERIAL PRIMARY KEY,
    full_name  VARCHAR(80)  NOT NULL,
    email      VARCHAR(120) NOT NULL UNIQUE,
    role       VARCHAR(20)  NOT NULL CHECK (role IN ('SUPPORT','COMPLIANCE','ADMIN')),
    region_id  SMALLINT     NOT NULL REFERENCES regions(region_id)
);

-- Wallet customers
CREATE TABLE customers (
    customer_id   SERIAL PRIMARY KEY,
    first_name    VARCHAR(40)  NOT NULL,
    last_name     VARCHAR(40)  NOT NULL,
    email         VARCHAR(120) NOT NULL UNIQUE,
    phone         VARCHAR(14)  NOT NULL UNIQUE CHECK (phone ~ '^\+234[0-9]{10}$'),
    date_of_birth DATE         NOT NULL CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '18 years'),
    region_id     SMALLINT     NOT NULL REFERENCES regions(region_id),
    kyc_tier      SMALLINT     NOT NULL DEFAULT 1 CHECK (kyc_tier BETWEEN 1 AND 3),
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- KYC evidence; one customer can submit many documents (1:N)
CREATE TABLE kyc_documents (
    doc_id       SERIAL PRIMARY KEY,
    customer_id  INT         NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    doc_type     VARCHAR(20) NOT NULL CHECK (doc_type IN ('NIN','BVN','PASSPORT','DRIVERS_LICENCE','UTILITY_BILL')),
    doc_ref      VARCHAR(30) NOT NULL,
    status       VARCHAR(10) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','VERIFIED','REJECTED')),
    verified_by  INT REFERENCES staff(staff_id),
    verified_at  TIMESTAMPTZ,
    UNIQUE (doc_type, doc_ref),
    CHECK ((status = 'VERIFIED') = (verified_by IS NOT NULL AND verified_at IS NOT NULL))
);

-- A customer can hold many accounts (1:N)
CREATE TABLE accounts (
    account_id     SERIAL PRIMARY KEY,
    customer_id    INT           NOT NULL REFERENCES customers(customer_id) ON DELETE RESTRICT,
    account_number CHAR(10)      NOT NULL UNIQUE CHECK (account_number ~ '^[0-9]{10}$'),  -- NUBAN style
    account_type   VARCHAR(10)   NOT NULL CHECK (account_type IN ('WALLET','SAVINGS','CURRENT')),
    balance        NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),               -- no overdraft
    status         VARCHAR(10)   NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','FROZEN','CLOSED')),
    opened_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE TABLE merchants (
    merchant_id SERIAL PRIMARY KEY,
    name        VARCHAR(80) NOT NULL,
    category    VARCHAR(30) NOT NULL,
    region_id   SMALLINT    NOT NULL REFERENCES regions(region_id)
);

-- Debit cards linked to an account (1:N)
CREATE TABLE cards (
    card_id     SERIAL PRIMARY KEY,
    account_id  INT        NOT NULL REFERENCES accounts(account_id),
    masked_pan  CHAR(16)   NOT NULL,              -- only first 6 + last 4 stored (PCI-DSS / NDPA minimisation)
    expiry      DATE       NOT NULL,
    status      VARCHAR(10) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','BLOCKED','EXPIRED'))
);

-- A transfer moves money between two accounts (Account is related to itself via Transfer)
CREATE TABLE transfers (
    transfer_id   BIGSERIAL PRIMARY KEY,
    from_account  INT           NOT NULL REFERENCES accounts(account_id),
    to_account    INT           NOT NULL REFERENCES accounts(account_id),
    amount        NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    status        VARCHAR(10)   NOT NULL DEFAULT 'PENDING'
                  CHECK (status IN ('PENDING','SUCCESS','FAILED','REVERSED')),
    reference     UUID          NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CHECK (from_account <> to_account)
);

-- Ledger: every debit/credit posted to an account
CREATE TABLE transactions (
    txn_id       BIGSERIAL PRIMARY KEY,
    account_id   INT           NOT NULL REFERENCES accounts(account_id),
    txn_type     VARCHAR(12)   NOT NULL CHECK (txn_type IN ('DEPOSIT','WITHDRAWAL','TRANSFER','POS','BILL','AIRTIME')),
    direction    CHAR(2)       NOT NULL CHECK (direction IN ('DR','CR')),
    amount       NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    status       VARCHAR(10)   NOT NULL DEFAULT 'SUCCESS' CHECK (status IN ('SUCCESS','FAILED','REVERSED')),
    merchant_id  INT           REFERENCES merchants(merchant_id),
    transfer_id  BIGINT        REFERENCES transfers(transfer_id),
    channel      VARCHAR(10)   NOT NULL CHECK (channel IN ('APP','USSD','POS','WEB')),
    created_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CHECK (NOT (txn_type = 'TRANSFER' AND transfer_id IS NULL))
);

-- Audit trail (security / NDPA 2023 accountability)
CREATE TABLE audit_log (
    audit_id    BIGSERIAL PRIMARY KEY,
    table_name  TEXT        NOT NULL,
    record_id   BIGINT      NOT NULL,
    action      VARCHAR(10) NOT NULL,
    old_data    JSONB,
    new_data    JSONB,
    changed_by  TEXT        NOT NULL DEFAULT current_user,
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger: every balance change on accounts is written to audit_log
CREATE OR REPLACE FUNCTION trg_audit_balance() RETURNS trigger AS $$
BEGIN
    IF NEW.balance IS DISTINCT FROM OLD.balance OR NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO audit_log(table_name, record_id, action, old_data, new_data)
        VALUES ('accounts', NEW.account_id, 'UPDATE',
                jsonb_build_object('balance', OLD.balance, 'status', OLD.status),
                jsonb_build_object('balance', NEW.balance, 'status', NEW.status));
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER accounts_audit AFTER UPDATE ON accounts
FOR EACH ROW EXECUTE FUNCTION trg_audit_balance();

-- Role-based access control (least privilege)
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='support_role')    THEN CREATE ROLE support_role;    END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='compliance_role') THEN CREATE ROLE compliance_role; END IF;
END $$;
GRANT SELECT ON customers, accounts, transactions, transfers TO support_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO compliance_role;
REVOKE ALL ON audit_log FROM support_role;
