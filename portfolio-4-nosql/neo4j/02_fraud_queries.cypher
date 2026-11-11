// Q1. Circular money flow (possible laundering ring): cycles of 3-5 transfers back to the start
MATCH path = (a:Account)-[:SENT*3..5]->(a)
WITH path, [r IN relationships(path) | r.amount] AS amounts
RETURN [n IN nodes(path) | n.id] AS ring, amounts
LIMIT 5;

// Q2. Several customers logging in from the SAME device (account takeover / mule network)
MATCH (c:Customer)-[:USES]->(d:Device)
WITH d, collect(c.name) AS customers, count(c) AS n
WHERE n > 1
RETURN d.id AS device, n AS customers_sharing, customers;

// Q3. Combine both signals: ring accounts whose owners share a device
MATCH (c1:Customer)-[:USES]->(d:Device)<-[:USES]-(c2:Customer),
      (c1)-[:OWNS]->(a1:Account)-[:SENT]->(a2:Account)<-[:OWNS]-(c2)
RETURN DISTINCT d.id AS device, c1.name AS sender, c2.name AS receiver;

// Q4. Shortest money path between two customers (investigation tool)
MATCH (x:Customer {id: 500})-[:OWNS]->(ax:Account),
      (y:Customer {id: 799})-[:OWNS]->(ay:Account),
      p = shortestPath((ax)-[:SENT*..6]->(ay))
RETURN [n IN nodes(p) | n.id] AS money_path;
