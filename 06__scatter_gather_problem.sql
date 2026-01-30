SET track_io_timing = ON;

-- Partition key is present in WHERE clause, so partition pruning is possible.
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders_partitioned
WHERE order_date BETWEEN '2025-02-01' AND '2025-02-10'
  AND customer_id = 1234;

-- Partition key is absent in WHERE clause, so partition pruning doesn't work.
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders_partitioned
WHERE customer_id = 1234;
