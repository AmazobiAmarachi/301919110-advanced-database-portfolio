-- Portfolio 1 - 03_constraint_tests.sql
-- Proves that integrity constraints reject invalid data. Each statement is EXPECTED to fail.
\set ON_ERROR_STOP off
\echo '--- Test 1: negative balance (CHECK balance >= 0)'
UPDATE accounts SET balance = -500 WHERE account_id = 1;
\echo '--- Test 2: duplicate email (UNIQUE)'
INSERT INTO customers(first_name,last_name,email,phone,date_of_birth,region_id)
SELECT first_name,last_name,email,'+2348099999999',date_of_birth,region_id FROM customers WHERE customer_id=1;
\echo '--- Test 3: invalid Nigerian phone format (CHECK regex)'
INSERT INTO customers(first_name,last_name,email,phone,date_of_birth,region_id)
VALUES ('Test','User','test@mail.ng','08012345678','1990-01-01',1);
\echo '--- Test 4: under-18 customer (CHECK date_of_birth)'
INSERT INTO customers(first_name,last_name,email,phone,date_of_birth,region_id)
VALUES ('Young','User','young@mail.ng','+2348011111111','2015-05-05',1);
\echo '--- Test 5: account for non-existent customer (FOREIGN KEY)'
INSERT INTO accounts(customer_id,account_number,account_type) VALUES (99999,'5000000001','WALLET');
\echo '--- Test 6: transfer to the same account (CHECK from <> to)'
INSERT INTO transfers(from_account,to_account,amount) VALUES (1,1,1000);
\echo '--- Test 7: delete a customer who still has accounts (ON DELETE RESTRICT)'
DELETE FROM customers WHERE customer_id = 1;
