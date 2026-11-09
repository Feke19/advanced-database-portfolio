
const kh = db.getSiblingDB("CashFlow");

// Start clean so the script can be re-run
["products", "customers", "orders"].forEach((c) => kh.getCollection(c).drop());

kh.createCollection("products", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["sku", "name", "price", "stock"],
      properties: {
        sku: { bsonType: "string" },
        name: { bsonType: "string" },
        price: { bsonType: "decimal", minimum: 0 }, // Decimal128 avoids float rounding on money
        stock: { bsonType: "number", minimum: 0 },
        tags: { bsonType: "array", items: { bsonType: "string" } },
      },
    },
  },
});

kh.createCollection("customers", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "name", "email"],
      properties: {
        name: { bsonType: "string" },
        email: { bsonType: "string", pattern: "^.+@.+$" },
        addresses: { bsonType: "array" },
      },
    },
  },
});

kh.createCollection("orders", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [
        "orderId",
        "customerId",
        "status",
        "orderDate",
        "items",
        "total",
      ],
      properties: {
        status: {
          enum: ["PENDING", "PAID", "SHIPPED", "DELIVERED", "CANCELLED"],
        },
        items: { bsonType: "array", minItems: 1 },
        total: { bsonType: "decimal", minimum: 0 },
      },
    },
  },
});

// Unique indexes (equivalent of UNIQUE constraints in SQL)
kh.products.createIndex({ sku: 1 }, { unique: true });
kh.customers.createIndex({ email: 1 }, { unique: true });
kh.orders.createIndex({ orderId: 1 }, { unique: true });

kh.products.insertMany([
  {
    sku: "LAP-001",
    name: "Aero 14 Laptop",
    description: "Lightweight 14-inch laptop",
    category: {
      name: "Laptops",
      path: ["Electronics", "Computers", "Laptops"],
    },
    price: NumberDecimal("450000.00"),
    stock: 12,
    specs: { cpu: "Core i5", ramGB: 16, storageGB: 512, screenInch: 14 },
    tags: ["laptop", "portable", "work"],
    reviews: [
      {
        user: "cust_001",
        rating: 5,
        comment: "Fast and light",
        date: new Date("2026-08-20"),
      },
    ],
    ratingAvg: 5,
    reviewCount: 1,
    createdAt: new Date("2026-01-10"),
  },

  {
    sku: "LAP-002",
    name: "Zen 15 Laptop",
    description: "Performance laptop for creators",
    category: {
      name: "Laptops",
      path: ["Electronics", "Computers", "Laptops"],
    },
    price: NumberDecimal("780000.00"),
    stock: 5,
    specs: { cpu: "Core i7", ramGB: 32, storageGB: 1024, screenInch: 15.6 },
    tags: ["laptop", "creator", "gaming"],
    reviews: [],
    ratingAvg: 0,
    reviewCount: 0,
    createdAt: new Date("2026-02-01"),
  },

  {
    sku: "PHN-001",
    name: "Nova X Smartphone",
    description: "6.5-inch smartphone with dual SIM",
    category: { name: "Phones", path: ["Electronics", "Phones"] },
    price: NumberDecimal("320000.00"),
    stock: 40,
    specs: { ramGB: 8, storageGB: 256, battery_mAh: 5000, dualSim: true },
    colors: ["Black", "Blue"],
    tags: ["phone", "android", "5g"],
    reviews: [],
    ratingAvg: 0,
    reviewCount: 0,
    createdAt: new Date("2026-03-05"),
  },

  {
    sku: "SHO-001",
    name: "Runner Pro Sneakers",
    description: "Breathable running sneakers",
    category: { name: "Shoes", path: ["Fashion", "Shoes"] },
    price: NumberDecimal("25000.00"),
    stock: 100,
    sizes: [40, 41, 42, 43, 44],
    colors: ["White", "Black", "Red"],
    material: "Mesh",
    tags: ["shoes", "running", "sport"],
    reviews: [
      {
        user: "cust_002",
        rating: 4,
        comment: "Comfortable",
        date: new Date("2026-09-20"),
      },
    ],
    ratingAvg: 4,
    reviewCount: 1,
    createdAt: new Date("2026-03-15"),
  },

  {
    sku: "ACC-001",
    name: "Wireless Earbuds",
    description: "Bluetooth earbuds with charging case",
    category: { name: "Accessories", path: ["Electronics", "Accessories"] },
    price: NumberDecimal("45000.00"),
    stock: 80,
    specs: { bluetooth: "5.3", batteryHours: 24, waterproof: "IPX4" },
    tags: ["wireless", "bluetooth", "audio"],
    reviews: [],
    ratingAvg: 0,
    reviewCount: 0,
    createdAt: new Date("2026-04-01"),
  },

  {
    sku: "HOM-001",
    name: "Smart Desk Lamp",
    description: "Dimmable LED lamp with wireless charging pad",
    category: { name: "Home", path: ["Home", "Lighting"] },
    price: NumberDecimal("18000.00"),
    stock: 60,
    specs: { wattage: 10, dimmable: true },
    tags: ["lamp", "wireless", "office"],
    reviews: [],
    ratingAvg: 0,
    reviewCount: 0,
    createdAt: new Date("2026-04-12"),
  },
]);

kh.customers.insertMany([
  {
    _id: "cust_001",
    name: "Amaka Obi",
    email: "amaka@example.com",
    phone: "08011111111",
    addresses: [
      {
        label: "Home",
        street: "12 Allen Avenue",
        city: "Lagos",
        country: "Nigeria",
        isDefault: true,
      },
    ],
    createdAt: new Date("2026-01-05"),
  },
  {
    _id: "cust_002",
    name: "Tunde Bello",
    email: "tunde@example.com",
    phone: "08022222222",
    addresses: [
      {
        label: "Home",
        street: "5 Wuse Road",
        city: "Abuja",
        country: "Nigeria",
        isDefault: true,
      },
      {
        label: "Office",
        street: "9 Garki Close",
        city: "Abuja",
        country: "Nigeria",
        isDefault: false,
      },
    ],
    createdAt: new Date("2026-02-11"),
  },
  {
    _id: "cust_003",
    name: "Zainab Musa",
    email: "zainab@example.com",
    phone: "08033333333",
    addresses: [
      {
        label: "Home",
        street: "3 Ahmadu Bello Way",
        city: "Kano",
        country: "Nigeria",
        isDefault: true,
      },
    ],
    createdAt: new Date("2026-03-20"),
  },
]);

kh.orders.insertMany([
  {
    orderId: 1001,
    customerId: "cust_001",
    status: "DELIVERED",
    orderDate: new Date("2026-08-05T10:15:00Z"),
    shippingAddress: {
      street: "12 Allen Avenue",
      city: "Lagos",
      country: "Nigeria",
    },
    items: [
      {
        sku: "LAP-001",
        name: "Aero 14 Laptop",
        category: "Laptops",
        unitPrice: NumberDecimal("450000.00"),
        quantity: 1,
      },
      {
        sku: "ACC-001",
        name: "Wireless Earbuds",
        category: "Accessories",
        unitPrice: NumberDecimal("45000.00"),
        quantity: 2,
      },
    ],
    payment: {
      method: "CARD",
      status: "SUCCESSFUL",
      paidAt: new Date("2026-08-05T10:20:00Z"),
    },
    delivery: {
      courier: "DHL",
      trackingNumber: "TRK000001001",
      status: "DELIVERED",
    },
    total: NumberDecimal("540000.00"),
  },

  {
    orderId: 1002,
    customerId: "cust_002",
    status: "PAID",
    orderDate: new Date("2026-09-14T14:30:00Z"),
    shippingAddress: {
      street: "5 Wuse Road",
      city: "Abuja",
      country: "Nigeria",
    },
    items: [
      {
        sku: "SHO-001",
        name: "Runner Pro Sneakers",
        category: "Shoes",
        unitPrice: NumberDecimal("25000.00"),
        quantity: 2,
      },
      {
        sku: "HOM-001",
        name: "Smart Desk Lamp",
        category: "Home",
        unitPrice: NumberDecimal("18000.00"),
        quantity: 1,
      },
    ],
    payment: {
      method: "WALLET",
      status: "SUCCESSFUL",
      paidAt: new Date("2026-09-14T14:32:00Z"),
    },
    total: NumberDecimal("68000.00"),
  },

  {
    orderId: 1003,
    customerId: "cust_001",
    status: "SHIPPED",
    orderDate: new Date("2026-10-02T09:00:00Z"),
    shippingAddress: {
      street: "12 Allen Avenue",
      city: "Lagos",
      country: "Nigeria",
    },
    items: [
      {
        sku: "PHN-001",
        name: "Nova X Smartphone",
        category: "Phones",
        unitPrice: NumberDecimal("320000.00"),
        quantity: 1,
      },
    ],
    payment: {
      method: "BANK_TRANSFER",
      status: "SUCCESSFUL",
      paidAt: new Date("2026-10-02T09:10:00Z"),
    },
    delivery: {
      courier: "GIG Logistics",
      trackingNumber: "TRK000001003",
      status: "IN_TRANSIT",
    },
    total: NumberDecimal("320000.00"),
  },

  {
    orderId: 1004,
    customerId: "cust_003",
    status: "CANCELLED",
    orderDate: new Date("2026-10-10T16:45:00Z"),
    shippingAddress: {
      street: "3 Ahmadu Bello Way",
      city: "Kano",
      country: "Nigeria",
    },
    items: [
      {
        sku: "LAP-002",
        name: "Zen 15 Laptop",
        category: "Laptops",
        unitPrice: NumberDecimal("780000.00"),
        quantity: 1,
      },
    ],
    payment: { method: "CARD", status: "FAILED" },
    total: NumberDecimal("780000.00"),
  },
]);

print("products:  " + kh.products.countDocuments());
print("customers: " + kh.customers.countDocuments());
print("orders:    " + kh.orders.countDocuments());

try {
  kh.products.insertOne({
    sku: "BAD-001",
    name: "Invalid Item",
    price: NumberDecimal("-5"),
    stock: 1,
  });
} catch (e) {
  print("Validation correctly rejected invalid document: " + e.codeName);
}
