-- Inspect hit rate: how many blocks were read from disk and how many were found in the buffer cache
SELECT
    relname AS table_name,
    heap_blks_read AS from_disk,
    heap_blks_hit AS from_cache,
    CASE
        WHEN (heap_blks_hit + heap_blks_read) > 0
            THEN ROUND(100.0 * heap_blks_hit / (heap_blks_hit + heap_blks_read), 2)
        ELSE 0
        END AS hit_rate_pct
FROM pg_statio_user_tables
WHERE (heap_blks_hit + heap_blks_read) > 0
ORDER BY heap_blks_hit + heap_blks_read DESC
LIMIT 10;