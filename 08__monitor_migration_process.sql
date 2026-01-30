
-- See which processes are running
SELECT pid, query, state,
       now() - query_start AS duration,
       wait_event_type, wait_event
FROM pg_stat_activity
WHERE state != 'idle' AND query NOT LIKE '%pg_stat_activity%';
