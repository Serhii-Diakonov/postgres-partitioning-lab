-- Perform aggregation over monolith table.
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders_monolith;

-- Perform aggregation over partition table.
-- We expecting to see that Parallel Scan is used for partitions and slightly better performance.
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders_partitioned;