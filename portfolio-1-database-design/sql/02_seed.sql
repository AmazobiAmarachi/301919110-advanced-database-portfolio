-- =====================================================================
-- Portfolio 1 - 02_seed.sql : realistic synthetic data for PayNaija Wallet
-- All names and numbers are synthetic (no real personal data - NDPA 2023).
-- Volume: 8 regions, 2,000 customers, ~3,000 accounts, 200,000 ledger rows
-- =====================================================================
SELECT setseed(0.42);   -- makes the random data reproducible

INSERT INTO regions(region_name, zone) VALUES
 ('Lagos','South-West'),('Abuja FCT','North-Central'),('Rivers','South-South'),
 ('Kano','North-West'),('Enugu','South-East'),('Oyo','South-West'),
 ('Kaduna','North-West'),('Anambra','South-East');

INSERT INTO staff(full_name, email, role, region_id) VALUES
 ('Tunde Bakare','tunde.b@paynaija.ng','SUPPORT',1),
 ('Ngozi Eze','ngozi.e@paynaija.ng','COMPLIANCE',1),
 ('Musa Bello','musa.b@paynaija.ng','SUPPORT',4),
 ('Aisha Lawal','aisha.l@paynaija.ng','ADMIN',2);

INSERT INTO customers(first_name, last_name, email, phone, date_of_birth, region_id, kyc_tier, created_at)
SELECT f, l,
       lower(f||'.'||l||g||'@mail.ng'),
       '+234' || (7000000000 + g)::text,
       DATE '1960-01-01' + (random()*14000)::int,
       -- Lagos-heavy distribution, like a real fintech
       CASE WHEN random() < 0.45 THEN 1 ELSE 2 + (random()*6)::int END,
       1 + (random()*2)::int,
       now() - (random()*730 || ' days')::interval
FROM generate_series(1,2000) g,
     LATERAL (SELECT (ARRAY['Chinedu','Amaka','Tunde','Bisi','Ibrahim','Zainab','Emeka','Ngozi','Segun','Halima','Uche','Fatima'])[1+floor(random()*12)] f,
                     (ARRAY['Okafor','Adeyemi','Bello','Eze','Musa','Okonkwo','Balogun','Abubakar','Nwosu','Ojo'])[1+floor(random()*10)] l
              WHERE g > 0) n;

INSERT INTO kyc_documents(customer_id, doc_type, doc_ref, status, verified_by, verified_at)
SELECT customer_id, 'NIN', lpad((10000000000 + customer_id*7919)::text, 11, '0'),
       CASE WHEN customer_id % 10 = 0 THEN 'PENDING' ELSE 'VERIFIED' END,
       CASE WHEN customer_id % 10 = 0 THEN NULL ELSE 2 END,
       CASE WHEN customer_id % 10 = 0 THEN NULL ELSE created_at + interval '1 day' END
FROM customers;

-- Every customer has a wallet; ~50% also have a savings account
INSERT INTO accounts(customer_id, account_number, account_type, balance, opened_at)
SELECT customer_id, lpad((3000000000 + customer_id)::text,10,'0'), 'WALLET',
       round((random()*500000)::numeric,2), created_at FROM customers;
INSERT INTO accounts(customer_id, account_number, account_type, balance, opened_at)
SELECT customer_id, lpad((4000000000 + customer_id)::text,10,'0'), 'SAVINGS',
       round((random()*2000000)::numeric,2), created_at + interval '30 days'
FROM customers WHERE random() < 0.5;

INSERT INTO merchants(name, category, region_id)
SELECT 'Merchant '||g, (ARRAY['Supermarket','Fuel','Restaurant','Pharmacy','Electronics','Transport'])[1+(g%6)], 1+(g%8)
FROM generate_series(1,50) g;

INSERT INTO cards(account_id, masked_pan, expiry)
SELECT account_id, '539983******'||lpad((account_id%10000)::text,4,'0'), DATE '2028-12-31'
FROM accounts WHERE account_type='WALLET';

-- 200,000 historical ledger entries over the last 12 months
INSERT INTO transactions(account_id, txn_type, direction, amount, status, merchant_id, channel, created_at)
SELECT a, t,
       CASE WHEN t IN ('DEPOSIT') THEN 'CR' ELSE 'DR' END,
       round((100 + random()*99900)::numeric, 2),
       CASE WHEN random() < 0.03 THEN 'FAILED' ELSE 'SUCCESS' END,
       CASE WHEN t='POS' THEN 1+(random()*49)::int END,
       (ARRAY['APP','USSD','POS','WEB'])[1+floor(random()*4)],
       now() - (random()*365 || ' days')::interval
FROM (SELECT 1 + floor(random()*(SELECT max(account_id) FROM accounts))::int a,
             (ARRAY['DEPOSIT','WITHDRAWAL','POS','BILL','AIRTIME'])[1+floor(random()*5)] t
      FROM generate_series(1,200000)) s;

ANALYZE;   -- refresh optimiser statistics
