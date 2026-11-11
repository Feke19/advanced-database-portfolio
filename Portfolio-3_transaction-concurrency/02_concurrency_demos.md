# Concurrency Demos (two terminals)
Reset before every demo:
```sql
UPDATE products SET stock_quantity = 5, price = 25000 WHERE sku = 'SKU-TEST-001';
UPDATE products SET stock_quantity = 0 WHERE sku = 'SKU-TEST-002';
```

## Demo 1: Lost update / overselling (the problem)
Two customers buy the last units at the same moment. The app reads stock, calculates in code, then writes the result back.

| Step | Session | SQL |
|---|---|---|
| 1 | A | `BEGIN;` |
| 2 | A | `SELECT stock_quantity FROM products WHERE sku='SKU-TEST-001';` -- sees 5 |
| 3 | B | `BEGIN;` |
| 4 | B | `SELECT stock_quantity FROM products WHERE sku='SKU-TEST-001';` -- also sees 5 |
| 5 | A | `UPDATE products SET stock_quantity = 5 - 3 WHERE sku='SKU-TEST-001';` (buys 3) |
| 6 | A | `COMMIT;` |
| 7 | B | `UPDATE products SET stock_quantity = 5 - 4 WHERE sku='SKU-TEST-001';` (buys 4) |
| 8 | B | `COMMIT;` |
| 9 | any | `SELECT stock_quantity FROM products WHERE sku='SKU-TEST-001';` |

**Result:** stock shows **1**, but 7 units were sold from a stock of 5. Session B overwrote Session A's change using a stale value. This is a **lost update**.

---

## Demo 2: Fix with pessimistic locking (`SELECT ... FOR UPDATE`)

| Step | Session | SQL |
|---|---|---|
| 1 | A | `BEGIN;` |
| 2 | A | `SELECT stock_quantity FROM products WHERE sku='SKU-TEST-001' FOR UPDATE;` -- 5, row locked |
| 3 | B | `BEGIN;` |
| 4 | B | `SELECT stock_quantity FROM products WHERE sku='SKU-TEST-001' FOR UPDATE;` -- **blocks (waiting)** |
| 5 | A | `UPDATE products SET stock_quantity = stock_quantity - 3 WHERE sku='SKU-TEST-001';` |
| 6 | A | `COMMIT;` -- Session B unblocks and now sees **2** |
| 7 | B | Only 2 left, but customer wants 4, so `ROLLBACK;` |

**Result:** the second buyer is forced to wait, sees the true stock, and the oversell is prevented.

## Demo 3: Fix with an atomic conditional UPDATE (no explicit lock needed)
```sql
UPDATE products
SET stock_quantity = stock_quantity - 4
WHERE sku = 'SKU-TEST-001' AND stock_quantity >= 4;

```
Try it in both sessions with the Demo 1 timing. Row-level locking makes the second statement wait, then re-check the condition against the new committed value.

---

## Demo 4: Isolation levels, non-repeatable read
**4a. READ COMMITTED (PostgreSQL default)**

| Step | Session | SQL |
|---|---|---|
| 1 | A | `BEGIN;` |
| 2 | A | `SELECT price FROM products WHERE sku='SKU-TEST-001';` -- 25000 |
| 3 | B | `UPDATE products SET price = 30000 WHERE sku='SKU-TEST-001';` (autocommits) |
| 4 | A | `SELECT price FROM products WHERE sku='SKU-TEST-001';` -- **30000** (changed mid-transaction) |
| 5 | A | `COMMIT;` |

**4b. REPEATABLE READ** (reset price to 25000 first)

| Step | Session | SQL |
|---|---|---|
| 1 | A | `BEGIN ISOLATION LEVEL REPEATABLE READ;` |
| 2 | A | `SELECT price FROM products WHERE sku='SKU-TEST-001';` -- 25000 |
| 3 | B | `UPDATE products SET price = 30000 WHERE sku='SKU-TEST-001';` |
| 4 | A | `SELECT price FROM products WHERE sku='SKU-TEST-001';` -- **still 25000** (snapshot) |
| 5 | A | `UPDATE products SET stock_quantity = stock_quantity - 1 WHERE sku='SKU-TEST-001';` |
|   |   | `ERROR: could not serialize access due to concurrent update` |
| 6 | A | `ROLLBACK;` (the app would retry the whole transaction) |

## Demo 5: Dirty read is not possible
| Step | Session | SQL |
|---|---|---|
| 1 | A | `BEGIN; UPDATE products SET price = 1 WHERE sku='SKU-TEST-001';` (not committed) |
| 2 | B | `SELECT price FROM products WHERE sku='SKU-TEST-001';` -- still sees **25000** |
| 3 | A | `ROLLBACK;` |

PostgreSQL treats `READ UNCOMMITTED` as `READ COMMITTED`, so uncommitted data is never visible.

---

## Demo 6: Deadlock and how to prevent it
Two orders that contain the same two products, locking them in opposite order.

| Step | Session | SQL |
|---|---|---|
| 1 | A | `BEGIN; UPDATE products SET stock_quantity = stock_quantity WHERE sku='SKU-TEST-001';` |
| 2 | B | `BEGIN; UPDATE products SET stock_quantity = stock_quantity WHERE sku='SKU-TEST-002';` |
| 3 | A | `UPDATE products SET stock_quantity = stock_quantity WHERE sku='SKU-TEST-002';` -- waits for B |
| 4 | B | `UPDATE products SET stock_quantity = stock_quantity WHERE sku='SKU-TEST-001';` -- waits for A |

After about 1 second PostgreSQL reports `ERROR: deadlock detected` in one session and aborts it; the other proceeds. Ran `ROLLBACK;` in both sessions.