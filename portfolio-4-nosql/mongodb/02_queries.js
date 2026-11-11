// Portfolio 4 - MongoDB CRUD, aggregation and query-plan evidence.  Run: mongosh paynaija 02_queries.js
// Q1. Find a customer's full profile by phone (single document read - no joins needed)
printjson(db.customers.findOne({ phone: "+2347000000003" }));

// Q2. Schema flexibility: add a NEW field to one customer only (no ALTER TABLE, no downtime)
db.customers.updateOne({ _id: 3 }, { $set: { bvn_linked: true, next_of_kin: { name: "Emeka Adeyemi", phone: "+2348030000000" } } });
db.customers.updateOne({ _id: 3 }, { $push: { devices: { os: "Android", model: "Infinix Hot 40" } } });
printjson(db.customers.findOne({ _id: 3 }, { name: 1, devices: 1, bvn_linked: 1, next_of_kin: 1 }));

// Q3. Customers with UNVERIFIED KYC in Lagos (query inside an embedded array)
print(db.customers.countDocuments({ region: "Lagos", "kyc.status": "PENDING" }));

// Q4. Aggregation pipeline: number of customers and total wallet balance per region
printjson(db.customers.aggregate([
  { $unwind: "$accounts" },
  { $match: { "accounts.type": "WALLET" } },
  { $group: { _id: "$region", customers: { $sum: 1 }, total_balance: { $sum: "$accounts.balance" } } },
  { $sort: { total_balance: -1 } }
]).toArray());

// Q5. Account statement from the referenced transactions collection
printjson(db.transactions.find({ account_id: 1450 }).sort({ created_at: -1 }).limit(5).toArray());

// Q6. Query plan evidence: COLLSCAN without index vs IXSCAN with index
db.transactions.dropIndex({ account_id: 1, created_at: -1 });
printjson(db.transactions.find({ account_id: 1450 }).explain("executionStats").executionStats);
db.transactions.createIndex({ account_id: 1, created_at: -1 });
printjson(db.transactions.find({ account_id: 1450 }).explain("executionStats").executionStats);
