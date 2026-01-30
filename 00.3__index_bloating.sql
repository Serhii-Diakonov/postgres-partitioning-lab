CREATE EXTENSION IF NOT EXISTS pgstattuple;

-- Inspect index state: the higher avg_leaf_density is, the better index works on table
-- On index bloated tables avg_leaf_density can be under 50% which results in poor performance
-- and have deep tree_level
SELECT tree_level, index_size, avg_leaf_density, leaf_fragmentation
FROM pgstatindex('idx_monolith_date');

DO
$$
    BEGIN
        FOR i IN 1..10
            LOOP
                UPDATE orders_monolith
                SET amount     = RANDOM() * 100,
                    order_date = order_date - INTERVAL '1 day'
                WHERE
                    order_date = TIMESTAMP '2025-01-01' + RANDOM() * (TIMESTAMP '2025-12-31' - TIMESTAMP '2025-01-01');

                DELETE
                FROM orders_monolith
                WHERE
                    order_date = TIMESTAMP '2025-01-01' + RANDOM() * (TIMESTAMP '2025-12-31' - TIMESTAMP '2025-01-01');

                INSERT INTO orders_monolith (order_date, customer_id, amount, payload)
                VALUES (TIMESTAMP '2025-01-01' + RANDOM() * (TIMESTAMP '2025-12-31' - TIMESTAMP '2025-01-01'),
                        (RANDOM() * 10000)::INT,
                        (RANDOM() * 500)::DECIMAL,
                        'New background order');

                COMMIT;
            END LOOP;
    END
$$;

SELECT *
FROM pgstatindex('idx_monolith_date');

VACUUM FULL orders_monolith;

SELECT *
FROM orders_monolith
WHERE order_date >= '2025-01-01'
  AND order_date <= '2025-02-01';