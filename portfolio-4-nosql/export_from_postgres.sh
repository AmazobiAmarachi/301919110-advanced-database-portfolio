#!/usr/bin/env bash
# Portfolio 4 - export PayNaija data from PostgreSQL for MongoDB (JSON) and Neo4j (CSV)
# Run from the portfolio-4-nosql folder:  bash export_from_postgres.sh
P="psql -d paynaija -qAt"
set -e
# --- MongoDB: customers as rich documents (embedded KYC, accounts, devices, preferences)
$P -c "SELECT json_agg(doc) FROM (
 SELECT json_build_object(
  '_id', c.customer_id, 'name', json_build_object('first',c.first_name,'last',c.last_name),
  'email', c.email, 'phone', c.phone, 'dob', c.date_of_birth, 'region', r.region_name, 'kyc_tier', c.kyc_tier,
  'kyc', (SELECT json_agg(json_build_object('type',k.doc_type,'ref',k.doc_ref,'status',k.status,'verified_at',k.verified_at)) FROM kyc_documents k WHERE k.customer_id=c.customer_id),
  'accounts', (SELECT json_agg(json_build_object('account_id',a.account_id,'number',a.account_number,'type',a.account_type,'balance',a.balance,'status',a.status)) FROM accounts a WHERE a.customer_id=c.customer_id),
  'devices', CASE WHEN c.customer_id % 3 = 0 THEN json_build_array(json_build_object('os','Android','model','TECNO Spark'),json_build_object('os','Web','browser','Chrome'))
                  ELSE json_build_array(json_build_object('os','iOS','model','iPhone 12')) END,
  'preferences', CASE WHEN c.customer_id % 4 = 0 THEN json_build_object('ussd_enabled',true,'language','Hausa') ELSE json_build_object('language','English') END,
  'created_at', c.created_at) doc
 FROM customers c JOIN regions r USING(region_id) ORDER BY c.customer_id) s;" > mongodb/customers.json
# --- MongoDB: 20,000 ledger rows as a separate (referenced) collection
$P -c "SELECT json_agg(json_build_object('_id',txn_id,'account_id',account_id,'type',txn_type,'direction',direction,'amount',amount,'status',status,'channel',channel,'merchant_id',merchant_id,'created_at',created_at)) FROM (SELECT * FROM transactions ORDER BY txn_id LIMIT 20000) t;" > mongodb/transactions.json
# --- Neo4j CSVs
echo "from_account,to_account,amount,created_at" > neo4j/transfers.csv
$P -F, -c "SELECT from_account,to_account,amount,to_char(created_at,'YYYY-MM-DD\"T\"HH24:MI:SS') FROM transfers WHERE status='SUCCESS' AND from_account NOT IN (101,102) AND to_account NOT IN (101,102) ORDER BY transfer_id" >> neo4j/transfers.csv
echo "account_id,customer_id,account_type" > neo4j/accounts.csv
$P -F, -c "SELECT account_id,customer_id,account_type FROM accounts ORDER BY 1" >> neo4j/accounts.csv
echo "customer_id,first_name,last_name,region" > neo4j/customers.csv
$P -F, -c "SELECT customer_id,first_name,last_name,region_name FROM customers JOIN regions USING(region_id) ORDER BY 1" >> neo4j/customers.csv
echo "customer_id,device_id" > neo4j/devices.csv
$P -F, -c "SELECT a.customer_id, CASE WHEN a.account_id IN (500,600,700,800) THEN 'DEV-7F3A-SHARED' ELSE 'DEV-'||lpad(a.customer_id::text,5,'0') END FROM accounts a WHERE a.account_type='WALLET' ORDER BY 1" >> neo4j/devices.csv
echo "Exported:"; ls -l mongodb/*.json neo4j/*.csv
echo "Ring account owners:"; $P -c "SELECT account_id, customer_id FROM accounts WHERE account_id IN (500,600,700,800) ORDER BY 1"
