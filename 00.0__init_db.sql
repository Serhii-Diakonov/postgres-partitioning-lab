SET search_path TO public;

CREATE TABLE orders_monolith
(
    id          serial,
    order_date  TIMESTAMP NOT NULL,
    customer_id INT,
    amount      DECIMAL(10, 2),
    payload     text
);

CREATE TABLE orders_partitioned
(
    id          serial,
    order_date  TIMESTAMP NOT NULL,
    customer_id INT,
    amount      DECIMAL(10, 2),
    payload     text
) PARTITION BY RANGE (order_date);

CREATE TABLE orders_2025_q1 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');
CREATE TABLE orders_2025_q2 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');
CREATE TABLE orders_2025_q3 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-07-01') TO ('2025-10-01');
CREATE TABLE orders_2025_q4 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-10-01') TO ('2026-01-01');

-- Takes about 20Gb on hard-drive. MacBook Pro M1 with 16Gb RAM performs operation in about 30 minutes.
INSERT INTO orders_monolith (order_date, customer_id, amount, payload)
SELECT TIMESTAMP '2025-01-01' + random() * (TIMESTAMP '2025-12-31' - TIMESTAMP '2025-01-01'),
       (random() * 10000)::int, (random() * 500)::decimal, md5(random()::text)
FROM generate_series(1, 250_000_000);

INSERT INTO orders_partitioned
SELECT *
FROM orders_monolith;

CREATE INDEX idx_monolith_date ON orders_monolith (order_date);
CREATE INDEX idx_partitioned_date ON orders_partitioned (order_date);


-- Fails because of index for partition doesn't contain partition key
ALTER TABLE orders_partitioned ADD PRIMARY KEY (id);

