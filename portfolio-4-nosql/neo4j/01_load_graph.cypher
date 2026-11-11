// Portfolio 4 - Graph model (Neo4j) for PayNaija fraud detection
// Copy the 4 CSV files into Neo4j's "import" folder, then run this script in Neo4j Browser.
CREATE CONSTRAINT customer_id IF NOT EXISTS FOR (c:Customer) REQUIRE c.id IS UNIQUE;
CREATE CONSTRAINT account_id  IF NOT EXISTS FOR (a:Account)  REQUIRE a.id IS UNIQUE;
CREATE CONSTRAINT device_id   IF NOT EXISTS FOR (d:Device)   REQUIRE d.id IS UNIQUE;

LOAD CSV WITH HEADERS FROM 'file:///customers.csv' AS row
MERGE (c:Customer {id: toInteger(row.customer_id)})
SET c.name = row.first_name + ' ' + row.last_name, c.region = row.region;

LOAD CSV WITH HEADERS FROM 'file:///accounts.csv' AS row
MATCH (c:Customer {id: toInteger(row.customer_id)})
MERGE (a:Account {id: toInteger(row.account_id)}) SET a.type = row.account_type
MERGE (c)-[:OWNS]->(a);

LOAD CSV WITH HEADERS FROM 'file:///devices.csv' AS row
MATCH (c:Customer {id: toInteger(row.customer_id)})
MERGE (d:Device {id: row.device_id})
MERGE (c)-[:USES]->(d);

LOAD CSV WITH HEADERS FROM 'file:///transfers.csv' AS row
MATCH (f:Account {id: toInteger(row.from_account)}), (t:Account {id: toInteger(row.to_account)})
CREATE (f)-[:SENT {amount: toFloat(row.amount), at: datetime(row.created_at)}]->(t);
