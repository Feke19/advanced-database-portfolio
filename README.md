# Porfolio 1: Database Design and Modelling

## Case Study

CashFlow is a simulated online store selling clothes, accessories.
-Users: Customers, Store Administrators, delivery staff.
-Main Data: Customers, Products, Orders, Order items, Payments, Addresses, Deliveries.
-Key Operations: Adding products, Placing orders, Tracking delivery, Processing payments, Updating stock

## What I did

1. Installed PostgreSQL(version 18.6-5) and created a database called CashFlow
2. Ran the code in the schema.sql to create 8 tables
3. Checked tables and constraints in pgAdmin
4. Created an ER diagram(screenshots/ER-Diagram.png)

# Portfolio 2: Query Processing and Optimisation (CashFlow)

Database: PostgreSQL. Uses the schema from `Portfolio-1_database-design/schema.sql`.

## How I implemented and tested this
1. Ran `01_seed_data.sql` to generate 50k customers, 5k products, 200k orders and 600k order items.
2. Ran each query in `02_queries.sql` with `EXPLAIN (ANALYZE, BUFFERS)` *before* indexing and saved the plans in `execution-plans` folder.
3. Created indexes with `03_indexes.sql`.
4. Re-ran the same queries and saved the "after" plans.
5. Compared results in the table below.

## Query processing in brief
PostgreSQL parses the query, rewrites it, and the **planner** estimates the cost of alternative plans (sequential scan vs index scan, nested loop vs hash join vs merge join) using table statistics, then the executor runs the cheapest. `EXPLAIN ANALYZE` shows both the estimate and what really happened.

## Performance analysis (write in your own words)
- **Q1/Q3:** Before the index, PostgreSQL had no shortcut, so it read all 200,000 orders and trashed the ones that didn’t belong to the customer. That’s the big “rows removed by filter” number in the plan. After the index, it jumps straight to that customer’s few orders, like using a book’s index instead of reading every page.

- **Q2:** The index sorts rows by status first, then by date within each status. PostgreSQL goes to PENDING, then reads the recent dates next to each other. If the date came first, the pending orders would be scattered all through the index. The rule: put the column you test with = first, and the range column (>=) second.

- **Q4:** An index helps when you want a small part of a table. Here PostgreSQL needs nearly all the rows, so reading them in order (a Seq Scan) is faster than jumping back and forth through an index. Most of the time goes on scanning, joining and grouping, which an index can’t speed up.

- **Q5:** A partial index only covers rows that match a condition, here status = 'SUCCESSFUL'. It’s smaller, faster to search and cheaper to keep updated, because failed or pending payments aren’t in it. In our test data every payment is successful, so the saving is small. In a real shop with many failed payments it would matter more.

## Evidence folder contents
- `execution-plans/` before/after text outputs
- `screenshots/` query results and plan outputs


# Portfolio 3: Transactions and Concurrency (CashFlow)

Database: PostgreSQL. Builds on the Portfolio 1 schema and Portfolio 2 seed data.

## Files
- `00_test_setup.sql` creates two test products (one with 5 in stock, one with 0)
- `01_commit_rollback.sql` atomicity: commit, rollback, savepoint
- `02_concurrency_demos.md` two-session demos of lost update, locking, isolation levels, deadlock

## Why transactions matter for e-commerce
Placing an order changes several tables at once (orders, order_items, products stock, payments). These must succeed or fail **together** (ACID):
- **Atomicity:** all steps happen or none do (Tests 1, 2, 4)
- **Consistency:** constraints such as `stock_quantity >= 0` are never violated
- **Isolation:** simultaneous customers do not corrupt each other's work (Demos 1 to 5)
- **Durability:** committed orders survive a crash (PostgreSQL write-ahead log)


