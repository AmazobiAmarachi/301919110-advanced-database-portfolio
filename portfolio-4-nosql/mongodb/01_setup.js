// Portfolio 4 - Document model (MongoDB) for PayNaija Wallet
// 1) Import:  mongoimport --db paynaija --collection customers    --jsonArray --file customers.json
//             mongoimport --db paynaija --collection transactions --jsonArray --file transactions.json
// 2) Run:     mongosh paynaija 01_setup.js
//
// Design decision:
//  - EMBED KYC documents, accounts summary, devices and preferences inside each customer:
//    they are always read together with the customer (one read = whole profile) and are bounded in size.
//  - REFERENCE transactions (separate collection with account_id): unbounded growth, would break
//    the 16 MB document limit and make customer documents huge.

// Schema validation: flexible, but core fields are enforced
db.runCommand({
  collMod: "customers",
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["name", "email", "phone", "region", "kyc_tier"],
    properties: {
      email:    { bsonType: "string", pattern: "^.+@.+$" },
      phone:    { bsonType: "string", pattern: "^\\+234[0-9]{10}$" },
      kyc_tier: { bsonType: "int", minimum: 1, maximum: 3 }
    } } },
  validationLevel: "moderate"
});

db.customers.createIndex({ phone: 1 }, { unique: true });
db.customers.createIndex({ "accounts.number": 1 });
db.transactions.createIndex({ account_id: 1, created_at: -1 });
