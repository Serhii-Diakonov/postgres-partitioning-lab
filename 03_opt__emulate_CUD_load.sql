
-- emulate CUD (create, update, delete) operations to create a load on DB. Optional
DO
$$
    BEGIN
        FOR i IN 1..1000
            LOOP
                UPDATE orders_partitioned
                SET amount = RANDOM() * 100
                WHERE id = (RANDOM() * 10000000)::INT;

                DELETE FROM orders_partitioned
                WHERE id = (random() * 10000000)::int;

                INSERT INTO orders_partitioned (order_date, customer_id, amount, payload)
                VALUES (TIMESTAMP '2025-01-01' + RANDOM() * (TIMESTAMP '2025-12-31' - TIMESTAMP '2025-01-01'),
                        (RANDOM() * 10000)::INT,
                        (RANDOM() * 500)::DECIMAL,
                        'New background order');

                IF i % 100 = 0 THEN
                    COMMIT;
                    PERFORM PG_SLEEP(0.1);
                END IF;
            END LOOP;
    END
$$;