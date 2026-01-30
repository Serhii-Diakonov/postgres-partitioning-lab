-- See how much storage is used by target tables
SELECT
    relname AS object_name,
    pg_size_pretty(pg_table_size(oid)) AS table_size,
    pg_size_pretty(pg_indexes_size(oid)) AS index_size,
    pg_size_pretty(pg_total_relation_size(oid)) AS total_size
FROM pg_class
WHERE relname IN ('orders_monolith', 'orders_partitioned')
   OR relname LIKE 'orders_2025_q%';

-- See relations between child tables (partitions) to parent table
SELECT
    nmsp_parent.nspname AS parent_schema,
    parent.relname      AS parent_table,
    nmsp_child.nspname  AS child_schema,
    child.relname       AS child_table,
    pg_size_pretty(pg_total_relation_size(child.oid)) AS child_total_size
FROM pg_inherits
         JOIN pg_class parent      ON pg_inherits.inhparent = parent.oid
         JOIN pg_class child       ON pg_inherits.inhrelid  = child.oid
         JOIN pg_namespace nmsp_parent ON nmsp_parent.oid  = parent.relnamespace
         JOIN pg_namespace nmsp_child  ON nmsp_child.oid   = child.relnamespace
WHERE parent.relname = 'orders_partitioned';