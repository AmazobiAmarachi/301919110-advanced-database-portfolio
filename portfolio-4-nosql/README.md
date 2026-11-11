# Portfolio 4: NoSQL and Advanced Data Models

**Case study:** the same PayNaija Wallet data, modelled in three NoSQL families · **Course link:** Session 1 (NoSQL types, NoSQL vs NewSQL), Session 5 (graph databases and knowledge graphs)

PayNaija keeps **money** in PostgreSQL, because balances need ACID. Three parts of the workload fit the relational model poorly, and each is moved to the NoSQL model that suits it (**polyglot persistence**):

| Workload | Problem in the relational model | NoSQL model chosen |
|---|---|---|
| Sessions, OTP / PIN rate limits, balance cache, live leaderboards | Very high read/write rate, short-lived data that should expire automatically | **Key-value**: Redis |
| Customer profile + KYC + devices + preferences | Semi-structured; fields differ between customers and change often (new KYC rules); needs 4–5 joins to assemble one profile | **Document**: MongoDB |
| Fraud and anti-money-laundering investigation | Questions are about *relationships* (rings, shared devices, paths), which need recursive self-joins in SQL | **Graph**: Neo4j |

---

## A. Key-value model: Redis (implemented and run)

Script: [`redis/redis_demo.sh`](redis/redis_demo.sh) · Output: [`results/redis_demo_output.txt`](results/redis_demo_output.txt)

| Key pattern | Redis type | Purpose | Expiry |
|---|---|---|---|
| `session:<token>` | Hash | Logged-in session (customer, device, IP, KYC tier) | 900 s (auto logout) |
| `pinfail:<customer_id>` | String counter | Brute-force protection: max 3 wrong PINs per 5 min | 300 s |
| `balance:acct:<id>` | String | Cache-aside copy of balance for the app home screen | 30 s, deleted on every transfer |
| `merchants:sales:today` | Sorted set | Real-time merchant leaderboard | daily |

```
redis> HSET session:9f2c1a customer_id 1450 device Android-TECNO-Spark ip 102.89.33.10 kyc_tier 2
4
redis> EXPIRE session:9f2c1a 900
redis> TTL session:9f2c1a
900
redis> INCR pinfail:1450
attempt 1 -> allowed (count=1)
attempt 2 -> allowed (count=2)
attempt 3 -> allowed (count=3)
attempt 4 -> BLOCKED (count=4)
redis> SET balance:acct:1450 128450.75 EX 30
redis> GET balance:acct:1450
128450.75
redis> DEL balance:acct:1450          <- cache invalidated after a transfer
redis> GET balance:acct:1450
(nil)
redis> ZREVRANGE merchants:sales:today 0 2 WITHSCORES
Merchant 7   45000
Merchant 12  42000
Merchant 3    8000
```
**Why it suits the workload.** Every operation is a single O(1) or O(log n) lookup by key, held in memory with sub-millisecond latency. TTL gives automatic expiry, which would need a scheduled cleanup job in SQL, and `INCR` is atomic, so two simultaneous wrong-PIN attempts cannot both "win". Redis gives no joins or ad-hoc queries, and limited durability, so it is used only for data that can be rebuilt. **Balances are never stored only in Redis.**

---

## B. Document model: MongoDB

Files: [`mongodb/customers.json`](mongodb/customers.json) (2,000 documents exported from the Portfolio 1 database), [`mongodb/transactions.json`](mongodb/transactions.json) (20,000 documents), [`mongodb/01_setup.js`](mongodb/01_setup.js), [`mongodb/02_queries.js`](mongodb/02_queries.js)

**Customer document** (one read returns the whole profile, which took 4 tables and 3 joins in PostgreSQL):
```json
{
  "_id": 3,
  "name": { "first": "Halima", "last": "Adeyemi" },
  "email": "halima.adeyemi3@mail.ng", "phone": "+2347000000003",
  "dob": "1967-06-10", "region": "Lagos", "kyc_tier": 3,
  "kyc": [ { "type": "NIN", "ref": "10000023757", "status": "VERIFIED", "verified_at": "2026-09-11T14:42:06+01:00" } ],
  "accounts": [ { "account_id": 3,    "number": "3000000003", "type": "WALLET",  "balance": 57569.77 },
                { "account_id": 2002, "number": "4000000003", "type": "SAVINGS", "balance": 1974675.21 } ],
  "devices": [ { "os": "Android", "model": "TECNO Spark" }, { "os": "Web", "browser": "Chrome" } ],
  "preferences": { "language": "English" }
}
```
Note that customer 4 has `"preferences": {"ussd_enabled": true, "language": "Hausa"}` while others do not. Documents in one collection do not need identical fields.

**Embed vs reference decisions**

| Data | Decision | Reason |
|---|---|---|
| KYC docs, devices, preferences, account summary | **Embed** | Always read with the customer; small and bounded (a customer has a few documents/devices) |
| Transactions | **Reference** (`account_id`) in a separate collection | Unbounded growth: embedding would breach MongoDB's 16 MB document limit and make every profile read slow |

**Operations implemented** (`02_queries.js`): find a profile by phone; add new fields to one customer only (`$set`, `$push`, with no `ALTER TABLE` and no downtime); query inside an embedded array (`"kyc.status": "PENDING"`); an aggregation pipeline (`$unwind → $match → $group → $sort`) for wallet balance per region; and `explain("executionStats")` showing **COLLSCAN** before and **IXSCAN** after `createIndex({account_id:1, created_at:-1})`. Flexibility is balanced by a `$jsonSchema` validator that still enforces email, phone format and KYC tier.

> **Evidence to add:** run `mongoimport` + `mongosh paynaija 02_queries.js` (MongoDB Community or Atlas) and save screenshots of Q1, Q4 and both `explain` outputs to `screenshots/`.

---

## C. Graph model: Neo4j (fraud detection)

Files: [`neo4j/00_generate_transfers.sql`](neo4j/00_generate_transfers.sql), CSV exports (`customers.csv`, `accounts.csv`, `devices.csv`, `transfers.csv`), [`neo4j/01_load_graph.cypher`](neo4j/01_load_graph.cypher), [`neo4j/02_fraud_queries.cypher`](neo4j/02_fraud_queries.cypher)

**Graph model (property graph)**
```
(:Customer {id, name, region}) -[:OWNS]->  (:Account {id, type})
(:Customer)                    -[:USES]->  (:Device {id})
(:Account)                     -[:SENT {amount, at}]-> (:Account)
```
Real transfer activity was generated in PostgreSQL through `transfer_funds()` (396 successful transfers), including a planted laundering pattern: ₦250,000 moved 500 → 600 → 700 → 800 → back to 500 within minutes, by four "different" customers who all log in from one device.

**Cypher, circular money flow** (the question that is hardest in SQL):
```cypher
MATCH path = (a:Account)-[:SENT*3..5]->(a)
RETURN [n IN nodes(path) | n.id] AS ring, [r IN relationships(path) | r.amount] AS amounts;
```
**Cypher, shared devices:**
```cypher
MATCH (c:Customer)-[:USES]->(d:Device)
WITH d, collect(c.name) AS customers, count(c) AS n WHERE n > 1
RETURN d.id, n, customers;
```
**Expected results**, validated on the exported data with Python NetworkX ([`results/graph_logic_validation.txt`](results/graph_logic_validation.txt)):
```
Transfer graph: 644 accounts, 396 SENT relationships
Q1 cycles of length 3-5 found: [[600, 700, 800, 500]]
Q2 devices shared by >1 customer: {'DEV-7F3A-SHARED': [500, 600, 699, 799]}
```
Both signals point to the same four customers, a strong indicator of a mule network. Compliance would freeze the accounts and file a suspicious transaction report.

**Why a graph suits this.** In SQL, a 3–5 hop cycle needs a recursive CTE that self-joins `transfers` repeatedly; cost grows with every hop and with table size. Neo4j stores relationships as direct pointers (*index-free adjacency*), so traversal cost depends on the number of relationships actually followed, not on the total data size. The trade-offs, as noted in Session 5, are a separate query language (Cypher vs SPARQL/Gremlin, no single standard), harder horizontal scaling, and data integration (here a nightly export from PostgreSQL).

> **Evidence to add:** load the CSVs into Neo4j Desktop or AuraDB Free, run both scripts, and screenshot the ring visualised in Neo4j Browser.

---

## D. Comparison and conclusion

| Criterion | PostgreSQL (relational) | Redis (key-value) | MongoDB (document) | Neo4j (graph) |
|---|---|---|---|---|
| Schema | Fixed, enforced | None | Flexible + optional validator | Flexible labels/properties |
| Query style | SQL, joins | GET/SET by key | Filters, aggregation pipeline | Pattern matching (Cypher) |
| Consistency model | ACID | Atomic single-key ops | ACID per document (multi-doc txns available) | ACID (single instance) |
| Scaling | Vertical + read replicas | Horizontal (cluster) | Horizontal (sharding) | Mostly vertical |
| Best PayNaija use | Balances, ledger, transfers | Sessions, rate limits, cache | Customer/KYC profiles | Fraud rings, investigations |

**NoSQL vs NewSQL.** If PayNaija outgrew a single PostgreSQL primary for the *ledger itself*, the answer would not be NoSQL (losing ACID on money is unacceptable). It would be a **NewSQL** database such as CockroachDB or Google Spanner, which keeps SQL and ACID while scaling horizontally (Session 1).
