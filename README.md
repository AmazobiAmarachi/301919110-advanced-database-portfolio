# Advanced Database Systems Portfolio: PayNaija Wallet

**Course:** MIT 8103 Advanced Database Systems, MIVA Open University (2026/2027, First Semester CA)
**Student:** Amazobi Amarachi · Student ID: *[insert]*
**Repository:** `advanced-database-portfolio` (private; assessor added as collaborator)

## Selected case study

**PayNaija Wallet** is a simulated Nigerian digital wallet and payments company (fintech) regulated by the CBN and subject to the **Nigeria Data Protection Act (NDPA) 2023**. Customers in eight states open wallet and savings accounts, fund them, pay merchants at POS terminals, buy airtime, pay bills and send money to other customers through the mobile app, USSD and the web.

| Element | Description |
|---|---|
| **Nature of the business** | Retail digital payments: wallets, savings, P2P transfers, merchant (POS) payments |
| **Users of the database** | Customers (through the app), customer-support staff, compliance/KYC officers, administrators, fraud analysts, management (reports) |
| **Major data stored** | Customers, KYC documents, accounts and balances, cards, merchants, transfers, ledger transactions, regions, staff, audit log |
| **Key operations** | Register customer and verify KYC · open account · deposit/withdraw · **transfer funds** · **reverse failed transfers** · generate statements · audit balances · detect fraud · regional management reports |

Fintech was chosen because it stresses every topic in the course: strict **ACID** transactions for money, heavy **query workloads** on a growing ledger, **semi-structured** KYC data suited to NoSQL, **highly connected** transfer data suited to graphs, and **high-availability** requirements across data centres.

## Portfolio index

| # | Folder | What it demonstrates | Key result |
|---|---|---|---|
| 1 | [`portfolio-1-database-design`](portfolio-1-database-design/) | ER model, 10-table 3NF schema, constraints, normalisation, RBAC, audit trigger | 7/7 invalid operations rejected by constraints |
| 2 | [`portfolio-2-query-optimisation`](portfolio-2-query-optimisation/) | 7 queries, `EXPLAIN ANALYZE` before/after, B+ tree, partial and composite indexes, query rewrite, materialised view | Statement query 10.9 ms → 0.16 ms (≈67×); report 146 ms → 0.11 ms |
| 3 | [`portfolio-3-transactions-concurrency`](portfolio-3-transactions-concurrency/) | COMMIT/ROLLBACK/SAVEPOINT, stored procedure, lost update, isolation levels, deadlock, load test | Naive transfers: 83% deadlock failures; ordered locking: 0% |
| 4 | [`portfolio-4-nosql`](portfolio-4-nosql/) | Redis key-value (live), MongoDB document model, Neo4j fraud graph | Fraud ring 500→600→700→800→500 and a shared device detected |
| 5 | [`portfolio-5-distributed-cloud`](portfolio-5-distributed-cloud/) | Streaming replication, sync vs async (CAP), failover, horizontal fragmentation, cloud design | Primary crash → standby promoted, zero committed data lost |

## Environment

| Component | Version | Use |
|---|---|---|
| PostgreSQL | 16.15 | Relational database, replication (P1, P2, P3, P5) |
| pgbench | 16.15 | Concurrency load test (P3) |
| Redis | 7.x | Key-value store (P4) |
| MongoDB / mongosh | 7.x | Document store (P4) |
| Neo4j | 5.x | Graph database (P4) |
| Graphviz | 2.x | ER and architecture diagrams |
| Docker Desktop | optional | Replica set on Windows/macOS (P5) |

## How to reproduce

```bash
createdb paynaija
psql -d paynaija -f portfolio-1-database-design/sql/01_schema.sql
psql -d paynaija -f portfolio-1-database-design/sql/02_seed.sql            # ~200,000 ledger rows
psql -d paynaija -f portfolio-1-database-design/sql/03_constraint_tests.sql
cd portfolio-2-query-optimisation && ./run_benchmark.sh before && psql -d paynaija -f sql/02_create_indexes.sql && ./run_benchmark.sh after
```
Each portfolio folder has its own README with step-by-step instructions, outputs and analysis.

## Documentation
- `docs/Amazobi_Amarachi_Documentation.pdf`: the 2–3 page LMS submission
- `docs/Amazobi_Amarachi_Portfolio_Evidence.pdf`: full evidence pack (all outputs and plans)
- `docs/AI_USE_DECLARATION.md`
