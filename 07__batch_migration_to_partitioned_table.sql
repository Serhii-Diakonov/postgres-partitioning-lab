CREATE OR REPLACE PROCEDURE migrate_data_batches(batch_size INT)
    LANGUAGE plpgsql
AS
$$
DECLARE
    rows_moved INT;
    current_id INT := 0;
    max_id     INT;
BEGIN
    SELECT MAX(id) INTO max_id FROM orders_monolith;

    LOOP
        INSERT INTO orders_partitioned_new
        SELECT *
        FROM orders_monolith
        WHERE id > current_id
          AND id <= current_id + batch_size;

        GET DIAGNOSTICS rows_moved = ROW_COUNT;
        EXIT WHEN rows_moved = 0;

        current_id := current_id + batch_size;
        RAISE NOTICE 'Moved % records from %...', current_id, max_id;
        COMMIT;

    END LOOP;

    RAISE NOTICE 'Migration finished successfully.';
END;
$$;


CREATE TABLE orders_partitioned_new
(
    id          SERIAL,
    order_date  TIMESTAMP NOT NULL,
    customer_id INT,
    amount      DECIMAL(10, 2),
    payload     TEXT
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_new_2025_q1 PARTITION OF orders_partitioned_new
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');
CREATE TABLE orders_new_2025_q2 PARTITION OF orders_partitioned_new
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');
CREATE TABLE orders_new_2025_q3 PARTITION OF orders_partitioned_new
    FOR VALUES FROM ('2025-07-01') TO ('2025-10-01');
CREATE TABLE orders_new_2025_q4 PARTITION OF orders_partitioned_new
    FOR VALUES FROM ('2025-10-01') TO ('2026-01-01');

CALL migrate_data_batches(50_000);