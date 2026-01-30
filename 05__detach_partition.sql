-- Perform DELETE which is basically slow and creates a lot of WAL logs
-- Requires VACUUM to clean up 'dead tuples'
DELETE
FROM orders_monolith
WHERE id <= 1000
  AND id >= 0;

-- Faster than the previous query because uses indexed column but still creates WAL logs
-- and requires VACUUMing
DELETE
FROM orders_monolith
WHERE order_date <= '2025-01-01'
  AND order_date >= '2025-04-01';

ALTER TABLE orders_partitioned DETACH PARTITION orders_2025_q2;

-- Verify that data is not accessible from parent table
SELECT * FROM orders_partitioned WHERE order_date >= '2025-04-01' AND order_date <= '2025-06-30';

-- Verify that data physically still exists after detaching
SELECT * FROM orders_2025_q2 LIMIT 100;

-- Physically delete the partition from disk. Basically a way faster than DELETE,
-- but on table of 20Gb not very demonstrative. Much better on really large tables (500Gb+)
DROP TABLE orders_2025_q3;