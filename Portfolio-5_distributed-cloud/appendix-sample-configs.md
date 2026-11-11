# Appendix: Illustrative Configuration Samples

> **Status: design illustrations, not tested deployments.** Hostnames are placeholders. Check the official documentation for your versions before using any of this.

## A. MongoDB replica set (3 nodes)

```javascript
rs.initiate({
  _id: "CashFlow-rs",
  members: [
    { _id: 0, host: "mongo-az-a.internal:27017", priority: 2 },
    { _id: 1, host: "mongo-az-b.internal:27017", priority: 1 },
    { _id: 2, host: "mongo-az-c.internal:27017", priority: 1 },
  ],
});
rs.status(); 
```

## B. Safe writes and read routing from the application

```javascript

db.orders.insertOne(orderDoc, { writeConcern: { w: "majority", j: true } });

db.products.find({ sku: "LAP-001" }).readPref("secondaryPreferred");

db.orders.find({ orderId: 1005 }).readPref("primary");
```

## C. Sharding orders by hashed customerId

```javascript
sh.enableSharding("CashFlow");
db.orders.createIndex({ customerId: "hashed" });
sh.shardCollection("CashFlow.orders", { customerId: "hashed" });
sh.status(); 
```

## D. PostgreSQL streaming replication (key settings only)

```ini

wal_level = replica
max_wal_senders = 5
synchronous_commit = on
synchronous_standby_names = 'FIRST 1 (standby_az_b)'   # commit waits for this standby
```

```sql
SELECT application_name, state, sync_state, replay_lag FROM pg_stat_replication;
```

## E. Range partitioning of orders by month (PostgreSQL)

```sql

CREATE TABLE orders_p (
    order_id    BIGINT GENERATED ALWAYS AS IDENTITY,
    customer_id INT NOT NULL,
    order_date  TIMESTAMP NOT NULL,
    status      VARCHAR(20) NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    PRIMARY KEY (order_id, order_date)
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2026_11 PARTITION OF orders_p
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE orders_2026_12 PARTITION OF orders_p
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');


EXPLAIN SELECT * FROM orders_p WHERE order_date >= '2026-11-15' AND order_date < '2026-11-20';
```

Note the design consequence: the partition column joins the primary key, so referencing `orders` by `order_id` alone from `order_items` would need a redesign. This is a real cost to mention in your analysis.
