
const kh = db.getSiblingDB("CashFlow");


print("\n--- A1: Laptops with at least 16GB RAM (nested field) ---");
printjson(
  kh.products
    .find(
      { "category.name": "Laptops", "specs.ramGB": { $gte: 16 } },
      { _id: 0, sku: 1, name: 1, price: 1, "specs.ramGB": 1 },
    )
    .toArray(),
);

print("\n--- A2: Shoes available in size 42 (array match) ---");
printjson(
  kh.products
    .find({ sizes: 42 }, { _id: 0, sku: 1, name: 1, sizes: 1 })
    .toArray(),
);

print('\n--- A3: Products tagged "wireless" under 50,000 ---');
printjson(
  kh.products
    .find(
      { tags: "wireless", price: { $lt: NumberDecimal("50000") } },
      { _id: 0, sku: 1, name: 1, price: 1 },
    )
    .toArray(),
);

print("\n--- A4: Order history for cust_001, newest first ---");
printjson(
  kh.orders
    .find(
      { customerId: "cust_001" },
      { _id: 0, orderId: 1, status: 1, orderDate: 1, total: 1 },
    )
    .sort({ orderDate: -1 })
    .toArray(),
);

print("\n--- B1: Atomic stock decrement (only if enough stock) ---");
printjson(
  kh.products.updateOne(
    { sku: "SHO-001", stock: { $gte: 2 } },
    { $inc: { stock: -2 } },
  ),
); // matchedCount 0 would mean "not enough stock", the document-DB equivalent of a conditional UPDATE

print("\n--- B2: Add a review and update counters in ONE atomic update ---");
printjson(
  kh.products.updateOne(
    { sku: "PHN-001" },
    {
      $push: {
        reviews: {
          user: "cust_001",
          rating: 5,
          comment: "Great battery",
          date: new Date(),
        },
      },
      $inc: { reviewCount: 1 },
      $set: { ratingAvg: 5 },
    },
  ),
);

print("\n--- B3: Move an order through its lifecycle ---");
printjson(
  kh.orders.updateOne(
    { orderId: 1002 },
    {
      $set: {
        status: "SHIPPED",
        delivery: {
          courier: "DHL",
          trackingNumber: "TRK000001002",
          status: "IN_TRANSIT",
        },
      },
    },
  ),
);

print(
  "\n--- B4: Add a new field to one document only (schema flexibility) ---",
);
printjson(
  kh.products.updateOne({ sku: "HOM-001" }, { $set: { energyRating: "A+" } }),
);

print("\n--- B5: Delete a discontinued product ---");
kh.products.insertOne({
  sku: "TMP-001",
  name: "Temp Item",
  price: NumberDecimal("1.00"),
  stock: 1,
});
printjson(kh.products.deleteOne({ sku: "TMP-001" }));

print(
  "\n--- C1: Revenue and units sold per category (excluding cancelled orders) ---",
);
printjson(
  kh.orders
    .aggregate([
      { $match: { status: { $ne: "CANCELLED" } } },
      { $unwind: "$items" },
      {
        $group: {
          _id: "$items.category",
          revenue: {
            $sum: { $multiply: ["$items.unitPrice", "$items.quantity"] },
          },
          unitsSold: { $sum: "$items.quantity" },
        },
      },
      { $sort: { revenue: -1 } },
    ])
    .toArray(),
);

print(
  "\n--- C2: Top customers by spend, joined to customer names with $lookup ---",
);
printjson(
  kh.orders
    .aggregate([
      { $match: { status: { $ne: "CANCELLED" } } },
      {
        $group: {
          _id: "$customerId",
          totalSpent: { $sum: "$total" },
          orders: { $sum: 1 },
        },
      },
      { $sort: { totalSpent: -1 } },
      { $limit: 3 },
      {
        $lookup: {
          from: "customers",
          localField: "_id",
          foreignField: "_id",
          as: "customer",
        },
      },
      { $unwind: "$customer" },
      {
        $project: {
          _id: 0,
          customer: "$customer.name",
          orders: 1,
          totalSpent: 1,
        },
      },
    ])
    .toArray(),
);

print("\n--- C3: Monthly revenue ---");
printjson(
  kh.orders
    .aggregate([
      { $match: { status: { $ne: "CANCELLED" } } },
      {
        $group: {
          _id: { $dateToString: { format: "%Y-%m", date: "$orderDate" } },
          revenue: { $sum: "$total" },
          orders: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ])
    .toArray(),
);

print("\n--- D0: Generate 50,000 extra products for a meaningful test ---");
const cats = ["Laptops", "Phones", "Shoes", "Accessories", "Home"];
for (let batch = 0; batch < 10; batch++) {
  const docs = [];
  for (let i = 1; i <= 5000; i++) {
    const n = batch * 5000 + i;
    docs.push({
      sku: "GEN-" + n,
      name: "Generated Product " + n,
      category: { name: cats[n % 5] },
      price: NumberDecimal((500 + Math.random() * 95000).toFixed(2)),
      stock: Math.floor(Math.random() * 500),
      tags: ["generated"],
      createdAt: new Date(),
    });
  }
  kh.products.insertMany(docs);
}
print("Total products: " + kh.products.countDocuments());

const q = {
  "category.name": "Accessories",
  price: { $lt: NumberDecimal("5000") },
};

print("\n--- D1: BEFORE index (expect COLLSCAN) ---");
let before = kh.products.find(q).explain("executionStats");
print(
  "stage: " +
    before.queryPlanner.winningPlan.stage +
    " | docsExamined: " +
    before.executionStats.totalDocsExamined +
    " | returned: " +
    before.executionStats.nReturned +
    " | ms: " +
    before.executionStats.executionTimeMillis,
);

kh.products.createIndex({ "category.name": 1, price: 1 }); // compound index
kh.products.createIndex({ name: "text", description: "text" }); // text search
kh.orders.createIndex({ customerId: 1, orderDate: -1 }); // order history

print("\n--- D2: AFTER index (expect IXSCAN inside FETCH) ---");
let after = kh.products.find(q).explain("executionStats");
printjson(after.queryPlanner.winningPlan);
print(
  "docsExamined: " +
    after.executionStats.totalDocsExamined +
    " | returned: " +
    after.executionStats.nReturned +
    " | ms: " +
    after.executionStats.executionTimeMillis,
);

print("\n--- D3: Text search ---");
printjson(
  kh.products
    .find({ $text: { $search: "wireless" } }, { _id: 0, sku: 1, name: 1 })
    .toArray(),
);

print("\n--- D4: Index list and sizes ---");
printjson(kh.products.getIndexes());
printjson(kh.products.stats().indexSizes);
