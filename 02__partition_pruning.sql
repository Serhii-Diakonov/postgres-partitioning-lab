
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders_monolith WHERE order_date >= '2025-05-01' and order_date <= '2025-06-01';

-- Partition Pruning happens: only one partition is scanned. Should be faster than the monolithic table.
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM orders_partitioned WHERE order_date >= '2025-05-01' and order_date <= '2025-06-01';
