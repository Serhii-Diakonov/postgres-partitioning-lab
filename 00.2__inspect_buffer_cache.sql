CREATE EXTENSION IF NOT EXISTS pg_buffercache;

-- See how much data is in the buffer cache
SELECT
    c.relname,
    pg_size_pretty(count(*) * 8192) as buffered,
    round(100.0 * count(*) /
          (SELECT setting::integer FROM pg_settings WHERE name = 'shared_buffers'),
          2) as buffer_percent
FROM pg_class c
         INNER JOIN pg_buffercache b ON b.relfilenode = c.relfilenode
GROUP BY c.oid, c.relname
ORDER BY 3 DESC
    LIMIT 10;